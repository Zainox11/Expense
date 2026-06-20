import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Service for checking network connectivity status.
/// Wraps connectivity_plus for clean architecture compliance.
class ConnectivityService {
  final Connectivity _connectivity;
  StreamController<bool>? _controller;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Checks if the device currently has an internet connection.
  /// Returns true if connected via WiFi, mobile, ethernet, or VPN.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Stream that emits connectivity status changes.
  /// Emits `true` when connected, `false` when disconnected.
  Stream<bool> get onConnectivityChanged {
    _controller ??= StreamController<bool>.broadcast();

    _connectivity.onConnectivityChanged.listen(
      (results) {
        final connected = _hasConnection(results);
        _controller?.add(connected);
      },
      onError: (error) {
        _controller?.add(false);
      },
    );

    return _controller!.stream;
  }

  /// Determines if any of the connectivity results indicate a connection.
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Clean up resources
  void dispose() {
    _controller?.close();
    _controller = null;
  }
}
