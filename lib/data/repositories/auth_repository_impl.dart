import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import 'package:expense_tracker/data/models/user_model.dart';
import 'package:expense_tracker/domain/entities/user_entity.dart';
import 'package:expense_tracker/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Firebase Auth and Google Sign-In.
///
/// User profile data is cached in a Hive box (`users`) for offline access,
/// so the app can display user info even when there is no network.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Box<UserModel> _userBox;

  static const String _currentUserKey = 'current_user';

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required Box<UserModel> userBox,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _userBox = userBox;

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return _cacheAndReturn(user);
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // Set the display name on the Firebase profile
    await user.updateDisplayName(displayName);
    await user.reload();

    // Fetch the refreshed user object
    final updatedUser = _firebaseAuth.currentUser!;
    return _cacheAndReturn(updatedUser);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user!;
    return _cacheAndReturn(user);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
    await _userBox.delete(_currentUserKey);
  }

  // ---------------------------------------------------------------------------
  // User info
  // ---------------------------------------------------------------------------

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Try Firebase first
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return _mapFirebaseUser(firebaseUser);
    }

    // Fall back to cached Hive data for offline access
    final cached = _userBox.get(_currentUserKey);
    return cached?.toEntity();
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      final entity = _mapFirebaseUser(firebaseUser);

      // Cache in the background (non-blocking)
      _cacheUser(entity);

      return entity;
    });
  }

  // ---------------------------------------------------------------------------
  // Password management
  // ---------------------------------------------------------------------------

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    await user.reload();

    // Re-cache with updated info
    final updatedUser = _firebaseAuth.currentUser!;
    await _cacheAndReturn(updatedUser);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Maps a Firebase [User] to our domain [UserEntity].
  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Caches the user entity in Hive and returns it.
  Future<UserEntity> _cacheAndReturn(User firebaseUser) async {
    final entity = _mapFirebaseUser(firebaseUser);
    await _cacheUser(entity);
    return entity;
  }

  /// Persists a [UserEntity] into the local Hive box.
  Future<void> _cacheUser(UserEntity entity) async {
    final model = UserModel.fromEntity(entity);
    await _userBox.put(_currentUserKey, model);
  }
}


