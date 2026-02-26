import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/offline_manager.dart';
import '../widgets/offline_widgets.dart';
import '../utils/error_handler.dart';

/// Base mixin for screens that need offline support
/// Provides common patterns for loading cached data and handling errors
mixin OfflineSupport<T extends StatefulWidget> on State<T> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  dynamic _cachedData;
  String? _cacheAge;
  NetworkService? _networkService;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  dynamic get cachedData => _cachedData;
  String? get cacheAge => _cacheAge;

  /// Cache key for this screen (override in subclass)
  String get cacheKey;

  /// Fetch fresh data from API (override in subclass)
  Future<dynamic> fetchData();

  /// Process and display data (override in subclass)
  void onDataLoaded(dynamic data);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Main data loading logic with offline fallback
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check network status
      final isOnline = _networkService?.isOnline ?? true;

      if (isOnline) {
        // Try to fetch fresh data
        try {
          final data = await fetchData();
          
          // Cache the fresh data
          await OfflineManager.saveData(cacheKey, data);
          
          // Display the data
          onDataLoaded(data);
          
          setState(() {
            _isLoading = false;
            _hasError = false;
            _cachedData = null;
            _cacheAge = null;
          });
        } catch (e) {
          ErrorHandler.logError('Fetch data for $cacheKey', e);
          
          // If fetch fails, try to load cached data
          await _loadCachedData(e);
        }
      } else {
        // Offline - load cached data
        await _loadCachedData(null);
      }
    } catch (e) {
      ErrorHandler.logError('Load data for $cacheKey', e);
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  /// Load cached data when offline or API fails
  Future<void> _loadCachedData(dynamic error) async {
    final hasCache = await OfflineManager.hasCache(cacheKey);
    
    if (hasCache) {
      final data = await OfflineManager.loadData(cacheKey);
      final age = await OfflineManager.getCacheAge(cacheKey);
      
      onDataLoaded(data);
      
      setState(() {
        _isLoading = false;
        _hasError = false;
        _cachedData = data;
        _cacheAge = age;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = error != null
            ? ErrorHandler.getErrorMessage(error)
            : 'No internet connection and no cached data available.';
      });
    }
  }

  /// Refresh data (pull-to-refresh)
  Future<void> refreshData() async {
    await _loadData();
  }

  /// Build UI with offline support
  Widget buildWithOfflineSupport({
    required Widget Function() builder,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    if (_isLoading) {
      return loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return errorWidget ?? 
        OfflineErrorScreen(
          message: _errorMessage,
          onRetry: refreshData,
        );
    }

    return Column(
      children: [
        if (_cachedData != null && _cacheAge != null)
          CachedDataBanner(lastUpdated: _cacheAge),
        Expanded(child: builder()),
      ],
    );
  }
}

/// Example implementation:
/// 
/// class MyModuleScreen extends StatefulWidget {
///   @override
///   State<MyModuleScreen> createState() => _MyModuleScreenState();
/// }
/// 
/// class _MyModuleScreenState extends State<MyModuleScreen> with OfflineSupport {
///   List<dynamic> _items = [];
///   
///   @override
///   String get cacheKey => OfflineManager.scheduleKey;
///   
///   @override
///   Future<dynamic> fetchData() async {
///     final snapshot = await SafeFirebaseCall.getData(
///       ref: FirebaseDatabase.instance.ref('schedule'),
///       context: 'Fetch schedule',
///     );
///     return snapshot.value;
///   }
///   
///   @override
///   void onDataLoaded(dynamic data) {
///     setState(() {
///       _items = (data as List?) ?? [];
///     });
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Schedule')),
///       body: buildWithOfflineSupport(
///         builder: () => ListView.builder(
///           itemCount: _items.length,
///           itemBuilder: (context, index) => ListTile(
///             title: Text(_items[index]['title']),
///           ),
///         ),
///       ),
///     );
///   }
/// }
