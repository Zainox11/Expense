import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service that wraps the `local_auth` plugin to provide biometric
/// authentication capabilities (fingerprint, face ID, iris).
///
/// Usage:
/// ```dart
/// final biometricService = BiometricService();
/// if (await biometricService.isAvailable()) {
///   final authenticated = await biometricService.authenticate();
///   if (authenticated) { /* grant access */ }
/// }
/// ```
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Cached list of available biometric types on this device.
  List<BiometricType> _availableBiometrics = [];

  // ---------------------------------------------------------------------------
  // Availability Checks
  // ---------------------------------------------------------------------------

  /// Returns `true` if the device hardware supports biometric authentication
  /// AND at least one biometric is enrolled.
  Future<bool> isAvailable() async {
    try {
      // Check if the device has biometric hardware
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      // Check if the device supports any form of local authentication
      // (biometric or device credential like PIN/pattern)
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        debugPrint('BiometricService: Device does not support biometrics');
        return false;
      }

      // Fetch and cache available biometric types
      _availableBiometrics = await _localAuth.getAvailableBiometrics();

      final available = _availableBiometrics.isNotEmpty;
      debugPrint(
        'BiometricService: isAvailable=$available '
        '(types=${_availableBiometrics.map((b) => b.name).join(", ")})',
      );
      return available;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error checking availability — $e');
      return false;
    }
  }

  /// Returns the list of biometric types the device supports and the user has
  /// enrolled (e.g., fingerprint, face, iris).
  ///
  /// Call [isAvailable] first to ensure the cache is populated, or this method
  /// will fetch the list fresh.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint(
        'BiometricService: Available biometrics = '
        '${_availableBiometrics.map((b) => b.name).join(", ")}',
      );
      return _availableBiometrics;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error fetching biometrics — $e');
      return [];
    }
  }

  /// Whether Face ID (or face recognition) is among the available biometrics.
  bool get isFaceIdAvailable =>
      _availableBiometrics.contains(BiometricType.face);

  /// Whether fingerprint authentication is among the available biometrics.
  bool get isFingerprintAvailable =>
      _availableBiometrics.contains(BiometricType.fingerprint);

  /// Whether iris scan authentication is among the available biometrics.
  bool get isIrisAvailable =>
      _availableBiometrics.contains(BiometricType.iris);

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Prompt the user for biometric authentication.
  ///
  /// [localizedReason] is displayed to the user explaining why authentication
  /// is needed. Defaults to a generic message if not provided.
  ///
  /// [useFallback] when `true`, allows the user to fall back to device
  /// credentials (PIN, pattern, password) if biometric auth fails.
  ///
  /// Returns `true` if authentication succeeded, `false` otherwise.
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access Expense Tracker',
    bool useFallback = true,
  }) async {
    try {
      // Ensure we have biometric capabilities before attempting
      final available = await isAvailable();
      if (!available) {
        debugPrint(
          'BiometricService: Authentication unavailable — '
          'no biometrics enrolled or hardware missing',
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true, // Keep auth session alive during app lifecycle events
          biometricOnly: !useFallback, // If false, allows device credentials fallback
          useErrorDialogs: true, // Show system error dialogs on failure
          sensitiveTransaction: true, // Marks as sensitive for OS-level protection
        ),
      );

      debugPrint('BiometricService: Authentication result=$authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Authentication error — ${e.message}');

      // Handle specific error codes for better UX
      switch (e.code) {
        case 'NotAvailable':
          debugPrint('BiometricService: Biometric hardware not available');
          break;
        case 'NotEnrolled':
          debugPrint('BiometricService: No biometrics enrolled on device');
          break;
        case 'LockedOut':
          debugPrint(
            'BiometricService: Too many failed attempts — temporarily locked',
          );
          break;
        case 'PermanentlyLockedOut':
          debugPrint(
            'BiometricService: Permanently locked out — '
            'device credentials required',
          );
          break;
        default:
          debugPrint(
            'BiometricService: Unhandled platform error code=${e.code}',
          );
      }

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancel any in-progress authentication dialog.
  ///
  /// Useful when navigating away from the lock screen.
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      debugPrint('BiometricService: Authentication cancelled');
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error cancelling auth — $e');
    }
  }
}
