import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flownote/models/user_model.dart';

/// Authentication service — Firebase Auth + Google Sign-In
class AuthService {
  final FirebaseAuth _auth       = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db    = FirebaseFirestore.instance;

  // Stream untuk mendengarkan perubahan auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Dapatkan user yang sedang login
  User? get currentUser => _auth.currentUser;

  /// ── Register dengan Email & Password ─────────────────────────────────────
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // Update display name
    await user.updateDisplayName(name);
    await user.reload();

    // Simpan profil ke Firestore
    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      avatarUrl: null,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(userModel.toJson());

    return userModel;
  }

  /// ── Login dengan Email & Password ────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebase(credential.user!);
  }

  /// ── Login dengan Google ───────────────────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    // Trigger alur Google Sign-In
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User membatalkan

    // Dapatkan token autentikasi
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Buat credential Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in ke Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Simpan/update profil di Firestore (upsert)
    final userModel = UserModel.fromFirebase(user);
    await _db.collection('users').doc(user.uid).set(
      userModel.toJson(),
      SetOptions(merge: true), // jangan overwrite data yang sudah ada
    );

    return userModel;
  }

  /// ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// ── Dapatkan profil user dari Firestore ──────────────────────────────────
  Future<UserModel?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return UserModel.fromFirebase(user);
    } catch (_) {
      return UserModel.fromFirebase(user);
    }
  }

  /// ── Cek apakah user sudah login ──────────────────────────────────────────
  bool get isLoggedIn => _auth.currentUser != null;
}
