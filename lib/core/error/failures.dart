/// Failure classes — represent typed error states throughout the app.
/// Use [Either<Failure, T>] pattern in repositories and use cases.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Firebase Authentication failures
class AuthFailure extends Failure {
  final String code;
  const AuthFailure(super.message, {this.code = ''});
}

/// Network / connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

/// Firestore / database read-write failures
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Terjadi kesalahan database.']);
}

/// Local cache failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal membaca data lokal.']);
}

/// Validation / input failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Generic server / unknown failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan server.']);
}

/// Map FirebaseAuthException codes to AuthFailure
AuthFailure mapFirebaseAuthError(String code) {
  final message = switch (code) {
    'user-not-found'        => 'Email tidak terdaftar.',
    'wrong-password'        => 'Password salah.',
    'invalid-credential'    => 'Email atau password salah.',
    'email-already-in-use'  => 'Email sudah digunakan akun lain.',
    'weak-password'         => 'Password terlalu lemah (min. 6 karakter).',
    'invalid-email'         => 'Format email tidak valid.',
    'too-many-requests'     => 'Terlalu banyak percobaan. Coba lagi nanti.',
    'network-request-failed'=> 'Tidak ada koneksi internet.',
    'user-disabled'         => 'Akun ini telah dinonaktifkan.',
    _                       => 'Terjadi kesalahan ($code). Coba lagi.',
  };
  return AuthFailure(message, code: code);
}
