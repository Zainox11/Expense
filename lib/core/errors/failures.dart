/// Base failure class for clean architecture error handling.
/// Failures represent expected error states that the UI layer can handle.
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;
}

/// Failure caused by a remote server error
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred. Please try again later.',
    super.statusCode,
  });
}

/// Failure caused by local cache operations
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local storage.',
    super.statusCode,
  });
}

/// Failure caused by authentication issues
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please sign in again.',
    super.statusCode,
  });

  /// Named constructors for common auth failures
  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Invalid email or password.',
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'No user found with this email.',
      );

  factory AuthFailure.emailInUse() => const AuthFailure(
        message: 'This email is already registered.',
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'Password is too weak. Use at least 6 characters.',
      );

  factory AuthFailure.accountDisabled() => const AuthFailure(
        message: 'This account has been disabled.',
      );

  factory AuthFailure.tooManyRequests() => const AuthFailure(
        message: 'Too many attempts. Please try again later.',
      );
}

/// Failure caused by network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.statusCode,
  });
}

/// Failure caused by invalid input or validation errors
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Invalid input. Please check your data.',
    super.statusCode,
  });
}

/// Failure for unknown/unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
  });
}
