import 'dart:async';
import 'dart:io';

/// Unified Service managing real-time internet connectivity checks for Kalmeda.
/// Ensures the application is only accessible when an active internet connection is present.
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;

  NetworkConnectivityService._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged =>
      _connectivityStreamController.stream;

  Timer? _periodicCheckTimer;

  /// Starts periodic connectivity monitoring.
  void startMonitoring({Duration interval = const Duration(seconds: 8)}) {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(interval, (_) {
      checkConnection();
    });
  }

  /// Stops periodic monitoring.
  void stopMonitoring() {
    _periodicCheckTimer?.cancel();
  }

  /// Verifies genuine internet reachability using DNS lookup and lightweight HTTP 204 probe.
  Future<bool> checkConnection({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    // 1. Primary DNS lookup check (Google DNS & Cloudflare)
    try {
      final lookupGoogle = await InternetAddress.lookup('google.com')
          .timeout(timeout);
      if (lookupGoogle.isNotEmpty && lookupGoogle[0].rawAddress.isNotEmpty) {
        _updateStatus(true);
        return true;
      }
    } catch (_) {}

    try {
      final lookupCloudflare = await InternetAddress.lookup('one.one.one.one')
          .timeout(timeout);
      if (lookupCloudflare.isNotEmpty &&
          lookupCloudflare[0].rawAddress.isNotEmpty) {
        _updateStatus(true);
        return true;
      }
    } catch (_) {}

    // 2. Secondary HTTP probe to Google's standard connectivity check endpoint
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final request = await client
          .getUrl(
            Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
          )
          .timeout(timeout);
      final response = await request.close().timeout(timeout);
      final success = response.statusCode == 204 ||
          (response.statusCode >= 200 && response.statusCode < 300);
      client.close();
      _updateStatus(success);
      return success;
    } catch (_) {
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      _connectivityStreamController.add(status);
    }
  }

  void dispose() {
    _periodicCheckTimer?.cancel();
    _connectivityStreamController.close();
  }
}
