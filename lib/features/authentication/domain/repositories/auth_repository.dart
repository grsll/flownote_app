import 'package:flownote/core/error/failures.dart';
import 'package:flownote/models/user_model.dart';

/// Abstract interface for authentication operations.
/// The presentation layer depends only on this interface — never on Firebase directly.
abstract interface class AuthRepository {
  /// Stream of the current auth state. Emits [UserModel] or null.
  Stream<UserModel?> get authStateChanges;

  /// Returns currently signed-in user, or null if not authenticated.
  UserModel? get currentUser;

  /// Register new user with email & password.
  /// Returns [AuthFailure] if registration fails.
  Future<(Failure?, UserModel?)> register({
    required String name,
    required String email,
    required String password,
  });

  /// Sign in with email & password.
  /// Returns [AuthFailure] if sign-in fails.
  Future<(Failure?, UserModel?)> login({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth.
  /// Returns null user (no failure) if user cancelled the flow.
  Future<(Failure?, UserModel?)> signInWithGoogle();

  /// Sign out from Firebase and Google.
  Future<Failure?> logout();

  /// Fetch full user profile from Firestore.
  Future<(Failure?, UserModel?)> getProfile();

  /// Update user profile fields in Firestore.
  Future<Failure?> updateProfile({
    String? name,
    String? avatarUrl,
    String? currency,
    String? language,
    UserSettings? settings,
  });
}
