import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/models/user_model.dart';
import 'package:flownote/services/auth_service.dart';

// ── Auth Status ───────────────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus  status;
  final UserModel?  user;
  final String?     error;
  final bool        isLoading;

  const AuthState({
    this.status    = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     error,
    bool?       isLoading,
  }) {
    return AuthState(
      status:    status    ?? this.status,
      user:      user      ?? this.user,
      error:     error,           // Allow explicit null to clear error
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    // Dengarkan perubahan auth state dari Firebase secara real-time
    _service.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: UserModel.fromFirebase(firebaseUser),
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Login dengan Email & Password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.login(email: email, password: password);
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login gagal');
      return false;
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code);
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Terjadi kesalahan. Coba lagi.');
      return false;
    }
  }

  /// Register dengan Email & Password
  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.register(name: name, email: email, password: password);
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Registrasi gagal');
      return false;
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code);
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Terjadi kesalahan. Coba lagi.');
      return false;
    }
  }

  /// Login dengan Google
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signInWithGoogle();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      }
      // User membatalkan Google Sign-In
      state = state.copyWith(isLoading: false, error: null);
      return false;
    } on FirebaseAuthException catch (e) {
      final message = _mapFirebaseError(e.code);
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign-In gagal. Coba lagi.');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Hapus pesan error
  void clearError() => state = state.copyWith(error: null);

  /// Map Firebase error code ke pesan yang ramah pengguna
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':       return 'Email tidak terdaftar.';
      case 'wrong-password':       return 'Password salah.';
      case 'email-already-in-use': return 'Email sudah digunakan akun lain.';
      case 'weak-password':        return 'Password terlalu lemah (min. 6 karakter).';
      case 'invalid-email':        return 'Format email tidak valid.';
      case 'too-many-requests':    return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed': return 'Tidak ada koneksi internet.';
      case 'invalid-credential':   return 'Email atau password salah.';
      default: return 'Terjadi kesalahan ($code). Coba lagi.';
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
