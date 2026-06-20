import 'package:expense_tracker/domain/entities/user_entity.dart';

/// Abstract repository interface for authentication operations.
/// Implemented by the data layer using Firebase Auth.
abstract class AuthRepository {
  /// Signs in with email and password.
  /// Returns the authenticated user entity.
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  /// Creates a new account with email, password, and display name.
  /// Returns the newly created user entity.
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Signs in with Google OAuth.
  /// Returns the authenticated user entity.
  Future<UserEntity> signInWithGoogle();

  /// Returns the currently authenticated user, or null if not signed in.
  Future<UserEntity?> getCurrentUser();

  /// Stream of authentication state changes.
  /// Emits the current user when auth state changes, or null on sign out.
  Stream<UserEntity?> authStateChanges();

  /// Sends a password reset email to the given address.
  Future<void> resetPassword(String email);
}
