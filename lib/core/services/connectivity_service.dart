import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus {
  connected,

  offline,

  serverUnreachable,

  unknown,
}

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  static const List<String> _primaryHosts = [
    'raw.githubusercontent.com',
    'google.com',
    'cloudflare.com',
  ];

  static const Duration _timeout = Duration(seconds: 5);

  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      for (final host in _primaryHosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(_timeout);
          if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
            return ConnectivityStatus.connected;
          }
        } on SocketException catch (_) {
          continue;
        } on TimeoutException catch (_) {
          continue;
        }
      }
      return ConnectivityStatus.offline;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return ConnectivityStatus.unknown;
    }
  }

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
