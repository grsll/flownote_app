import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flownote/models/user_model.dart';

/// Concrete Firebase implementation of [AuthRepository].
/// All Firebase/Google calls are contained here — presentation layer stays clean.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth    _auth;
  final GoogleSignIn    _googleSignIn;
  final FirebaseFirestore _db;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? db,
  })  : _auth        = auth        ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _db           = db          ?? FirebaseFirestore.instance;

  // ── Auth state stream ──────────────────────────────────────────────────────

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map(
      (user) => user != null ? UserModel.fromFirebase(user) : null,
    );
  }

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? UserModel.fromFirebase(user) : null;
  }

  // ── Register ────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, UserModel?)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);
      await user.reload();

      final userModel = UserModel(
        id:        user.uid,
        name:      name,
        email:     email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _upsertUserDoc(userModel);
      return (null, userModel);
    } on FirebaseAuthException catch (e) {
      return (mapFirebaseAuthError(e.code), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, UserModel?)> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userModel = UserModel.fromFirebase(credential.user!);
      return (null, userModel);
    } on FirebaseAuthException catch (e) {
      return (mapFirebaseAuthError(e.code), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  @override
  Future<(Failure?, UserModel?)> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (null, null); // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userModel = UserModel.fromFirebase(userCredential.user!);

      // Upsert — preserve existing Firestore data
      await _upsertUserDoc(userModel);
      return (null, userModel);
    } on FirebaseAuthException catch (e) {
      return (mapFirebaseAuthError(e.code), null);
    } catch (e) {
      return (ServerFailure('Google Sign-In gagal. Coba lagi.'), null);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  @override
  Future<Failure?> logout() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return null;
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }

  // ── Get Profile ───────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, UserModel?)> getProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return (AuthFailure('Pengguna tidak ditemukan.'), null);
    }
    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return (null, UserModel.fromJson(doc.data()!));
      }
      // Fallback to Firebase Auth data
      return (null, UserModel.fromFirebase(firebaseUser));
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat profil.'), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────────

  @override
  Future<Failure?> updateProfile({
    String? name,
    String? avatarUrl,
    String? currency,
    String? language,
    UserSettings? settings,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AuthFailure('Pengguna tidak ditemukan.');

    try {
      final updates = <String, dynamic>{
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };
      if (name != null) {
        updates['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }
      if (avatarUrl != null) updates['avatar_url']  = avatarUrl;
      if (currency  != null) updates['currency']    = currency;
      if (language  != null) updates['language']    = language;
      if (settings  != null) updates['settings']    = settings.toJson();

      await _db.collection('users').doc(uid).update(updates);
      return null;
    } on FirebaseException catch (e) {
      return DatabaseFailure(e.message ?? 'Gagal memperbarui profil.');
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────────

  Future<void> _upsertUserDoc(UserModel user) async {
    await _db.collection('users').doc(user.id).set(
      user.toJson(),
      SetOptions(merge: true), // never overwrite existing Firestore data
    );
  }
}
