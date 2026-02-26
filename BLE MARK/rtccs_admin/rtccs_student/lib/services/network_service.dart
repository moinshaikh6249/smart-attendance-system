import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
/// Used to check internet availability before API calls
class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _hasShownOfflineBanner = false;

  bool get isOnline => _isOnline;
  bool get hasShownOfflineBanner => _hasShownOfflineBanner;

  NetworkService() {
    _initConnectivity();
    _setupConnectivityListener();
  }

  /// Initialize connectivity status on app start
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = true; // Assume online if check fails
    }
  }

  /// Listen to connectivity changes
  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // Check if any connection type is available
    _isOnline = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    // Reset banner flag when coming back online
    if (!wasOnline && _isOnline) {
      _hasShownOfflineBanner = false;
    }

    notifyListeners();
  }

  /// Mark that offline banner has been shown
  void markOfflineBannerShown() {
    _hasShownOfflineBanner = true;
    notifyListeners();
  }

  /// Check if network is available before API call
  /// Returns true if online, false if offline
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return true; // Assume online if check fails
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
