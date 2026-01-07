import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Connectivity states for network-dependent operations
enum ConnectivityStatus {
  /// Device is connected to the internet
  connected,

  /// Device is offline (no network)
  offline,

  /// Network is available but server is unreachable
  serverUnreachable,

  /// Unknown connectivity status
  unknown,
}

/// A lightweight connectivity service that checks actual internet access
/// without requiring additional dependencies.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// Primary hosts to check for connectivity
  static const List<String> _primaryHosts = [
    'raw.githubusercontent.com', // Our update config host
    'google.com',
    'cloudflare.com',
  ];

  /// Timeout for connectivity checks
  static const Duration _timeout = Duration(seconds: 5);

  /// Checks if the device has internet connectivity by attempting to reach
  /// reliable external hosts.
  ///
  /// Returns [ConnectivityStatus.connected] if at least one host is reachable.
  /// Returns [ConnectivityStatus.offline] if no hosts are reachable.
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      // Try to lookup DNS for multiple hosts
      for (final host in _primaryHosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(_timeout);
          if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
            return ConnectivityStatus.connected;
          }
        } on SocketException catch (_) {
          // Host unreachable, try next
          continue;
        } on TimeoutException catch (_) {
          // Timeout, try next
          continue;
        }
      }
      return ConnectivityStatus.offline;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return ConnectivityStatus.unknown;
    }
  }

  /// Checks if the update server specifically is reachable.
  /// This is useful for distinguishing between "no internet" and "server down".
  Future<ConnectivityStatus> checkUpdateServerConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'raw.githubusercontent.com',
      ).timeout(_timeout);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return ConnectivityStatus.connected;
      }
      return ConnectivityStatus.serverUnreachable;
    } on SocketException catch (_) {
      // Check if it's a general network issue or server-specific
      final generalStatus = await checkConnectivity();
      if (generalStatus == ConnectivityStatus.connected) {
        return ConnectivityStatus.serverUnreachable;
      }
      return ConnectivityStatus.offline;
    } on TimeoutException catch (_) {
      return ConnectivityStatus.serverUnreachable;
    } catch (e) {
      debugPrint('Update server connectivity check error: $e');
      return ConnectivityStatus.unknown;
    }
  }

  /// Returns a human-readable message for each connectivity status
  static String getStatusMessage(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.connected:
        return 'Connected to internet';
      case ConnectivityStatus.offline:
        return 'No internet connection';
      case ConnectivityStatus.serverUnreachable:
        return 'Update server is temporarily unavailable';
      case ConnectivityStatus.unknown:
        return 'Unable to determine connection status';
    }
  }

  /// Returns the recovery action message for each connectivity status
  static String getRecoveryMessage(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.connected:
        return '';
      case ConnectivityStatus.offline:
        return 'Please connect to WiFi or mobile data and try again.';
      case ConnectivityStatus.serverUnreachable:
        return 'Please try again later. The update server may be undergoing maintenance.';
      case ConnectivityStatus.unknown:
        return 'Please check your network settings and try again.';
    }
  }
}
