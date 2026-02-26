# Offline Mode - Quick Implementation Guide

This guide shows how to quickly integrate offline support into existing screens.

---

## 🚀 Quick Start

### Step 1: Add NetworkService to Providers

In `lib/main.dart`:

```dart
import 'services/network_service.dart';

// Add to MultiProvider
providers: [
  ChangeNotifierProvider(create: (_) => NetworkService()),
  // ... other providers
],
```

### Step 2: Show Offline Banner in Main App

In `lib/main.dart` or root widget:

```dart
import 'package:provider/provider.dart';
import 'services/network_service.dart';
import 'widgets/offline_widgets.dart';

@override
Widget build(BuildContext context) {
  return Consumer<NetworkService>(
    builder: (context, networkService, child) {
      return Column(
        children: [
          if (!networkService.isOnline) const OfflineBanner(),
          Expanded(child: yourMainContent),
        ],
      );
    },
  );
}
```

---

## 📱 Add Offline Support to a Screen

### Option A: Use OfflineSupport Mixin (Recommended)

```dart
import '../utils/offline_mixin.dart';
import '../services/offline_manager.dart';
import '../utils/api_wrapper.dart';

class MyModuleScreen extends StatefulWidget {
  @override
  State<MyModuleScreen> createState() => _MyModuleScreenState();
}

class _MyModuleScreenState extends State<MyModuleScreen> 
    with OfflineSupport {
  
  List<dynamic> _items = [];
  
  // 1. Define cache key
  @override
  String get cacheKey => OfflineManager.scheduleKey; // or your custom key
  
  // 2. Define how to fetch fresh data
  @override
  Future<dynamic> fetchData() async {
    final snapshot = await SafeFirebaseCall.getData(
      ref: FirebaseDatabase.instance.ref('your/path'),
      context: 'Fetch module data',
    );
    return snapshot.value;
  }
  
  // 3. Define how to process loaded data
  @override
  void onDataLoaded(dynamic data) {
    setState(() {
      _items = (data as List?) ?? [];
    });
  }
  
  // 4. Build UI with offline support
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Module')),
      body: buildWithOfflineSupport(
        builder: () => RefreshIndicator(
          onRefresh: refreshData,
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(_items[index].toString()));
            },
          ),
        ),
      ),
    );
  }
}
```

### Option B: Manual Implementation

```dart
import '../services/network_service.dart';
import '../services/offline_manager.dart';
import '../utils/error_handler.dart';
import '../utils/api_wrapper.dart';
import '../widgets/offline_widgets.dart';

class MyModuleScreen extends StatefulWidget {
  @override
  State<MyModuleScreen> createState() => _MyModuleScreenState();
}

class _MyModuleScreenState extends State<MyModuleScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _items = [];
  String? _cacheAge;
  bool _isShowingCache = false;
  
  static const String _cacheKey = OfflineManager.scheduleKey;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Check network
      final networkService = Provider.of<NetworkService>(context, listen: false);
      final isOnline = await networkService.checkConnection();
      
      if (isOnline) {
        // Try to fetch fresh data
        try {
          final snapshot = await SafeFirebaseCall.getData(
            ref: FirebaseDatabase.instance.ref('your/path'),
            context: 'Fetch data',
          );
          
          final data = snapshot.value;
          
          // Cache the data
          await OfflineManager.saveData(_cacheKey, data);
          
          // Display
          setState(() {
            _items = (data as List?) ?? [];
            _isLoading = false;
            _isShowingCache = false;
          });
        } catch (e) {
          // Fetch failed - try cache
          await _loadCachedData(e);
        }
      } else {
        // Offline - load cache
        await _loadCachedData(null);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = ErrorHandler.getErrorMessage(e);
      });
    }
  }
  
  Future<void> _loadCachedData(dynamic error) async {
    final hasCache = await OfflineManager.hasCache(_cacheKey);
    
    if (hasCache) {
      final data = await OfflineManager.loadData(_cacheKey);
      final age = await OfflineManager.getCacheAge(_cacheKey);
      
      setState(() {
        _items = (data as List?) ?? [];
        _cacheAge = age;
        _isShowingCache = true;
        _isLoading = false;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Module')),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return OfflineErrorScreen(
        message: _errorMessage,
        onRetry: _loadData,
      );
    }
    
    return Column(
      children: [
        if (_isShowingCache && _cacheAge != null)
          CachedDataBanner(lastUpdated: _cacheAge),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_items[index].toString()));
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 🔧 Update Existing API Calls

### Before:
```dart
final snapshot = await FirebaseDatabase.instance.ref('path').get();
```

### After:
```dart
final snapshot = await SafeFirebaseCall.getData(
  ref: FirebaseDatabase.instance.ref('path'),
  context: 'Operation description',
);
```

### With Error Handling:
```dart
try {
  final snapshot = await SafeFirebaseCall.getData(
    ref: FirebaseDatabase.instance.ref('path'),
    context: 'Fetch student data',
  );
  // Process data
} catch (e) {
  ErrorHandler.logError('Load student data', e);
  
  final message = ErrorHandler.getErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

## ✅ Attendance Operations (DO NOT MODIFY LOGIC)

Only wrap with error handling - don't change the attendance code:

```dart
try {
  // EXISTING ATTENDANCE CODE (UNCHANGED)
  // ... your BLE/QR logic
  // ... validation
  // ... data preparation
  
  // Submit with timeout
  await SafeFirebaseCall.setData(
    ref: FirebaseDatabase.instance.ref('attendance/$path'),
    value: attendanceData,
    timeout: ApiConfig.quickTimeout,
    context: 'Mark attendance',
  );
  
  // Success
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Attendance marked successfully'),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  ErrorHandler.logError('Attendance marking', e);
  
  // Show attendance-specific error
  final message = ErrorHandler.getAttendanceErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## 📦 Custom Cache Keys

If you need a custom cache key for a new module:

```dart
// In OfflineManager, add:
static const String myModuleKey = '${_prefix}my_module';

// Then use in your screen:
@override
String get cacheKey => OfflineManager.myModuleKey;
```

---

## 🎨 Custom Error Screens

```dart
// For specific module error
ErrorScreen(
  message: 'Unable to load fees information. Please try again later.',
  onRetry: loadFeesData,
  icon: Icons.receipt_long,
)

// For offline with no cache
OfflineErrorScreen(
  message: 'Connect to the internet to view exam timetable.',
  onRetry: null, // No retry button if offline
)
```

---

## 📊 Show Cache Age

```dart
// Get cache age string
final age = await OfflineManager.getCacheAge(OfflineManager.scheduleKey);
// Returns: "Last updated 2 hours ago"

// Show in UI
if (age != null) {
  CachedDataBanner(lastUpdated: age)
}
```

---

## 🔄 Refresh/Retry Pattern

```dart
// Pull-to-refresh
RefreshIndicator(
  onRefresh: _loadData, // or refreshData() if using mixin
  child: yourContent,
)

// Retry button
ElevatedButton.icon(
  onPressed: _loadData,
  icon: Icon(Icons.refresh),
  label: Text('Retry'),
)
```

---

## ⚠️ Common Pitfalls

### ❌ DON'T:
```dart
// Don't modify attendance logic
if (offline) {
  // DON'T add custom BLE logic
  // DON'T change QR validation
  // DON'T modify attendance calculation
}

// Don't show technical errors
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(e.toString())), // ❌ Raw error
);
```

### ✅ DO:
```dart
// Only wrap with error handling
try {
  // Existing attendance code unchanged
  await existingAttendanceFunction();
} catch (e) {
  // User-friendly message
  final message = ErrorHandler.getAttendanceErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)), // ✅ User-friendly
  );
}
```

---

## 📋 Implementation Checklist

- [ ] Add `NetworkService` to providers in `main.dart`
- [ ] Show `OfflineBanner` in root widget when offline
- [ ] Update API calls to use `SafeFirebaseCall`
- [ ] Add offline support to each module screen
- [ ] Implement caching for module data
- [ ] Add error handling with user-friendly messages
- [ ] Test offline behavior for each screen
- [ ] Test error scenarios (timeout, server error, etc.)
- [ ] Verify attendance operations remain unchanged
- [ ] Add pull-to-refresh where appropriate

---

## 🆘 Quick Reference

### Files to Import
```dart
import '../services/network_service.dart';
import '../services/offline_manager.dart';
import '../utils/error_handler.dart';
import '../utils/api_wrapper.dart';
import '../widgets/offline_widgets.dart';
```

### Cache Keys
```dart
OfflineManager.dashboardKey
OfflineManager.scheduleKey
OfflineManager.calendarKey
OfflineManager.timetableKey
OfflineManager.feesKey
OfflineManager.resultKey
OfflineManager.internalMarksKey
OfflineManager.hallTicketKey
OfflineManager.profileKey
```

### Widgets
```dart
OfflineBanner()                    // Network status banner
CachedDataBanner()                 // Showing cached data
OfflineErrorScreen()               // No cache + no internet
ErrorScreen()                      // API error
OfflineLoadingPlaceholder()        // Loading cache
```

### API Wrapper Methods
```dart
SafeFirebaseCall.getData()
SafeFirebaseCall.setData()
SafeFirebaseCall.updateData()
SafeFirebaseCall.pushData()
SafeFirebaseCall.executeWithRetry()
```

---

**For full details, see:** `OFFLINE_MODE_GUIDELINES.md`
