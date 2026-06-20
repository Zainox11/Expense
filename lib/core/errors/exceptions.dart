/// Custom exception classes for the data layer.
/// Exceptions are thrown in repositories and caught by use cases,
/// which convert them into Failure objects for the presentation layer.

/// Base exception class with a message and optional status code
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when a remote server request fails
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred.',
    super.statusCode,
  });
}

/// Exception thrown when local cache operations fail
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache operation failed.',
    super.statusCode,
  });
}

/// Exception thrown when authentication operations fail
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed.',
    super.statusCode,
  });

  /// Named constructors for common Firebase Auth error codes
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthException(message: 'No user found with this email.');
      case 'wrong-password':
        return const AuthException(message: 'Incorrect password.');
      case 'invalid-email':
        return const AuthException(message: 'Invalid email address.');
      case 'email-already-in-use':
        return const AuthException(message: 'This email is already registered.');
      case 'weak-password':
        return const AuthException(message: 'Password is too weak.');
      case 'user-disabled':
        return const AuthException(message: 'This account has been disabled.');
      case 'too-many-requests':
        return const AuthException(message: 'Too many attempts. Try again later.');
      case 'operation-not-allowed':
        return const AuthException(message: 'This sign-in method is not enabled.');
      case 'invalid-credential':
        return const AuthException(message: 'Invalid credentials provided.');
      case 'account-exists-with-different-credential':
        return const AuthException(
          message: 'An account already exists with a different sign-in method.',
        );
      case 'network-request-failed':
        return const AuthException(message: 'Network error. Check your connection.');
      default:
        return AuthException(message: 'Authentication error: $code');
    }
  }
}

/// Exception thrown when there is no network connectivity
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection.',
    super.statusCode,
  });
}

/// Exception thrown for data format / parsing errors
class FormatException extends AppException {
  const FormatException({
    super.message = 'Data format error.',
    super.statusCode,
  });
}

/// Exception thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.statusCode,
  });
}
