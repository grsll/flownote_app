/// Custom exception types used in the data layer.
/// These are caught in repository implementations and mapped to [Failure] objects.

class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet.']);
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Terjadi kesalahan database.']);
}

class AuthException extends AppException {
  final String code;
  const AuthException(super.message, {this.code = ''});
}

class CacheException extends AppException {
  const CacheException([super.message = 'Gagal membaca data lokal.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan.']);
}
