# BLE Mark Student App - Offline Mode & Error Handling Guidelines

**Version:** 1.0  
**Last Updated:** November 29, 2025

---

## 📋 Overview

This document defines the global offline mode and error handling rules for the BLE Mark Student app. These guidelines ensure a consistent, user-friendly experience when network or API issues occur.

**CRITICAL:** These rules apply to **network, caching, and error display only**. They do NOT modify any attendance, BLE, or QR algorithms.

---

## 🌐 1. GENERAL NETWORK RULES

### Network Status Checking

**Before any API call:**
- Check network connectivity using `NetworkService`
- If network check fails, assume online and attempt operation
- Network checks should be non-blocking

### Offline Behavior

**When no internet connection is detected:**

1. **Show Non-Blocking Banner:**
   ```
   "No internet connection. Some features may not work."
   ```
   - Display at top of screen
   - Orange background with WiFi-off icon
   - Does not block UI interaction
   - Auto-dismisses when connection restored

2. **Attendance Operations (BLE/QR):**
   - Continue to work with existing implementation
   - Do not block or prevent attendance marking
   - If local logging/queueing exists, use it
   - Show appropriate error if server confirmation fails

### Implementation

```dart
// Check network before API call
final networkService = Provider.of<NetworkService>(context, listen: false);
final isOnline = await networkService.checkConnection();

if (!isOnline) {
  // Show offline banner (already handled by NetworkService)
  // Attempt to load cached data
  // Continue with offline logic
}
```

---

## 📱 2. SCREEN-BY-SCREEN OFFLINE BEHAVIOUR

### Dashboard Screen

**Online:**
- Load fresh attendance summary, recent activity
- Cache data for offline use

**Offline:**
- Load last cached data
- Show `CachedDataBanner`: "Showing cached data. Last updated X ago"
- If no cache: Show placeholders with "No data available offline"

**Implementation:**
```dart
// Dashboard loads cached data when offline
final cachedData = await OfflineManager.loadData(OfflineManager.dashboardKey);
final cacheAge = await OfflineManager.getCacheAge(OfflineManager.dashboardKey);
```

---

### Class Schedule Screen

**Online:**
- Fetch schedule from Firebase
- Cache for offline viewing

**Offline with cache:**
- Display cached schedule
- Show banner: "Showing last updated data. [Last updated X ago]"

**Offline without cache:**
- Show `OfflineErrorScreen`:
  ```
  "No internet connection and no cached data available."
  [Retry Button]
  ```

**Cache Key:** `OfflineManager.scheduleKey`

---

### Academic Calendar Screen

**Online:**
- Load events, holidays, exams
- Cache data

**Offline with cache:**
- Display cached events
- Show cache age banner

**Offline without cache:**
- Show offline error screen
- Provide retry button

**Cache Key:** `OfflineManager.calendarKey`

---

### Exam Timetable Screen

**Online:**
- Fetch exam schedule
- Cache data

**Offline with cache:**
- Display cached timetable
- Show "Showing last updated data"

**Offline without cache:**
- Show offline error screen
- "Connect to internet to view exam timetable"

**Cache Key:** `OfflineManager.timetableKey`

---

### Fees Screen

**Online:**
- Load fee structure, payments, dues
- Cache complete fee data

**Offline with cache:**
- Display cached fee information
- Show cache age

**Offline without cache:**
- Show offline error screen
- "No internet connection. Unable to load fees information."

**Cache Key:** `OfflineManager.feesKey`

---

### Result / Internal Marks Screen

**Online:**
- Fetch results from server
- Cache data securely

**Offline with cache:**
- Display cached results
- Show when last updated

**Offline without cache:**
- Show offline error screen
- "Connect to internet to view your results"

**Cache Keys:** 
- `OfflineManager.resultKey`
- `OfflineManager.internalMarksKey`

---

### Hall Ticket Screen

**Online:**
- Download hall ticket PDF/image
- Cache file locally

**Offline with cache:**
- Open cached file
- Show "Viewing offline copy"

**Offline without cache:**
- Show message:
  ```
  "Connect to the internet to load your hall ticket."
  [Go Back Button]
  ```

**Cache Key:** `OfflineManager.hallTicketKey`

---

### Student Profile Screen

**Online:**
- Load profile from Firebase
- Cache for offline viewing

**Offline with cache:**
- Display cached profile (view mode only)
- Disable edit functionality
- Show "Connect to internet to update profile"

**Offline without cache:**
- Show offline error screen

**Cache Key:** `OfflineManager.profileKey`

---

### Settings Screen

**Behavior:**
- Always accessible (no network required)
- Theme, notifications stored in `SharedPreferences`
- Cache clearing works offline
- Logout requires clearing local data only

---

## ⚠️ 3. API ERROR HANDLING (SERVER / BACKEND FAILURE)

### Error Response Handling

**For ANY module API call:**

| Error Type | User Message |
|------------|--------------|
| 500 Server Error | "Server error. Please try again later." |
| 404 Not Found | "Requested data not found." |
| 401/403 Auth Error | "Authentication failed. Please login again." |
| Timeout | "Request timed out. Please try again." |
| Network Error | "No internet connection. Please check your network." |
| Parse Error | "Invalid data received. Please try again." |
| Generic Error | "Unable to load data. Please try again later." |

### User-Friendly Messages

**DO:**
✅ Show simple, clear messages  
✅ Suggest actionable next steps  
✅ Provide retry button when appropriate  
✅ Allow user to navigate back safely  

**DON'T:**
❌ Show raw JSON responses  
❌ Display stack traces  
❌ Show technical error codes  
❌ Crash the app  

### Implementation

```dart
try {
  final data = await SafeFirebaseCall.getData(
    ref: FirebaseDatabase.instance.ref('path'),
    context: 'Fetch module data',
  );
  // Process data
} catch (e) {
  ErrorHandler.logError('Module load', e);
  
  // Show user-friendly message
  final userMessage = ErrorHandler.getErrorMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(userMessage)),
  );
  
  // Try to load cached data as fallback
  final cached = await OfflineManager.loadData(cacheKey);
  if (cached != null) {
    // Display cached data
  }
}
```

---

## ✅ 4. ATTENDANCE-SPECIFIC SAFETY

### BLE Attendance Marking

**Network/Server Failure During Marking:**

1. **Show Clear Error:**
   ```
   "Attendance could not be marked due to a network problem."
   ```

2. **Local Backup (if implemented):**
   - If local queueing exists, add to queue
   - Show: "Attendance saved locally. Will sync when online."

3. **Never Show False Success:**
   - Only show "Attendance marked successfully" if server confirms
   - If server doesn't respond, show network error

### QR Attendance Marking

**Same rules as BLE:**
- Clear error on network failure
- Use local queue if available
- Never claim success without server confirmation

### Implementation

```dart
try {
  // Existing BLE/QR attendance logic (unchanged)
  await markAttendance(...);
  
  // Show success only if no exception
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
  
  // If local queue exists, add to queue
  // (Do not modify existing BLE/QR logic)
}
```

---

## ⏱️ 5. TIMEOUT & RETRY

### Timeout Configuration

**Standard Timeouts:**
- Quick operations (get): **10 seconds**
- Standard operations: **15 seconds**
- File uploads/downloads: **30 seconds**

**Implementation:**
```dart
// Use SafeFirebaseCall wrapper for automatic timeout
final snapshot = await SafeFirebaseCall.getData(
  ref: FirebaseDatabase.instance.ref('path'),
  timeout: ApiConfig.standardTimeout, // 15 seconds
  context: 'Fetch data',
);
```

### Retry Logic

**Automatic Retry:**
- Maximum **2 retry attempts**
- **2-second delay** between retries
- Only for transient network errors

**User-Triggered Retry:**
- Show "Retry" button on error screens
- Allow manual refresh

**Implementation:**
```dart
// Automatic retry for critical operations
final data = await SafeFirebaseCall.executeWithRetry(
  operation: () => fetchCriticalData(),
  maxRetries: 2,
  context: 'Load attendance',
);

// Manual retry button
ElevatedButton.icon(
  onPressed: () => refreshData(),
  icon: Icon(Icons.refresh),
  label: Text('Retry'),
)
```

---

## 🛡️ 6. FALLBACK BEHAVIOUR

### Module Isolation

**Principle:** If any optional module fails, it must NOT affect:
- Login functionality
- Dashboard access
- Attendance operations (BLE/QR)

### Graceful Degradation

**If module completely fails:**

1. **Show Clear Error:**
   ```
   "Unable to load [Module Name]. [Error Message]"
   ```

2. **Allow Navigation Back:**
   - User can return to dashboard
   - App remains stable

3. **Don't Block Other Features:**
   - Other modules continue to work
   - Attendance always accessible

### Implementation

```dart
// Module screen with isolated error handling
class MyModuleScreen extends StatefulWidget {
  @override
  State<MyModuleScreen> createState() => _MyModuleScreenState();
}

class _MyModuleScreenState extends State<MyModuleScreen> 
    with OfflineSupport {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Module Name'),
        // Always allow back navigation
      ),
      body: buildWithOfflineSupport(
        builder: () {
          // Module content
        },
      ),
    );
  }
}
```

---

## 📊 7. LOGGING (SILENT DEBUG)

### Error Logging

**What to Log:**
- API errors with context
- Network failures
- Timeout events
- Parse/data errors

**How to Log:**
```dart
ErrorHandler.logError('Operation context', error, stackTrace);
```

**Where Logs Go:**
1. **Debug Mode:** Console output via `debugPrint`
2. **Production:** Remote error tracking (Firebase Crashlytics, Sentry, etc.)

### What NOT to Show

**Never show to students:**
❌ Internal error logs  
❌ Stack traces  
❌ Debug information  
❌ Database paths  
❌ API keys/tokens  

### Future Enhancement

```dart
// TODO: Integrate remote error tracking
// In ErrorHandler.logError():
if (kReleaseMode) {
  FirebaseCrashlytics.instance.recordError(error, stackTrace);
  // or
  Sentry.captureException(error, stackTrace: stackTrace);
}
```

---

## 🚫 8. MUST NOT CHANGE

### Protected Code Areas

**These implementations must remain UNCHANGED:**

1. **BLE Scanning Logic**
   - Device discovery
   - Signal strength processing
   - Beacon identification

2. **QR Code Scanning**
   - QR code validation
   - Data extraction
   - Security checks

3. **Attendance Calculation**
   - Percentage computation
   - Threshold checks
   - Status determination

4. **Attendance Storage**
   - Database schema
   - Data structure
   - Existing Firebase paths

### Only Behavior Changes

**What IS changed:**
- Network status checking before operations
- Error message display to users
- Cached data loading when offline
- Timeout handling for API calls
- User-facing error screens

**What is NOT changed:**
- Core attendance algorithms
- BLE/QR scanning implementation
- Database operations (only wrapped with timeout)
- Business logic

---

## 🔧 Implementation Files

### Core Services

| File | Purpose |
|------|---------|
| `lib/services/network_service.dart` | Monitor network connectivity |
| `lib/services/offline_manager.dart` | Cache management for offline data |

### Utilities

| File | Purpose |
|------|---------|
| `lib/utils/error_handler.dart` | User-friendly error messages |
| `lib/utils/api_wrapper.dart` | Timeout and retry for Firebase calls |
| `lib/utils/offline_mixin.dart` | Reusable offline support for screens |

### Widgets

| File | Purpose |
|------|---------|
| `lib/widgets/offline_widgets.dart` | Offline banner, error screens, placeholders |

---

## 📖 Usage Examples

### Example 1: Basic Module Screen with Offline Support

```dart
class ScheduleScreen extends StatefulWidget {
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> 
    with OfflineSupport {
  
  List<dynamic> _schedule = [];
  
  @override
  String get cacheKey => OfflineManager.scheduleKey;
  
  @override
  Future<dynamic> fetchData() async {
    return await SafeFirebaseCall.getData(
      ref: FirebaseDatabase.instance.ref('schedule'),
      context: 'Fetch schedule',
    );
  }
  
  @override
  void onDataLoaded(dynamic data) {
    setState(() {
      _schedule = (data as List?) ?? [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Class Schedule')),
      body: buildWithOfflineSupport(
        builder: () => RefreshIndicator(
          onRefresh: refreshData,
          child: ListView.builder(
            itemCount: _schedule.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_schedule[index]['subject']),
                subtitle: Text(_schedule[index]['time']),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### Example 2: API Call with Error Handling

```dart
Future<void> loadFeesData() async {
  setState(() => _isLoading = true);
  
  try {
    // Check network
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final isOnline = await networkService.checkConnection();
    
    if (isOnline) {
      // Fetch fresh data with timeout
      final snapshot = await SafeFirebaseCall.getData(
        ref: FirebaseDatabase.instance.ref('fees/$studentId'),
        timeout: ApiConfig.standardTimeout,
        context: 'Fetch fees data',
      );
      
      final data = snapshot.value;
      
      // Cache for offline use
      await OfflineManager.saveData(OfflineManager.feesKey, data);
      
      // Display data
      setState(() {
        _feesData = data;
        _isLoading = false;
      });
    } else {
      // Load cached data
      final cached = await OfflineManager.loadData(OfflineManager.feesKey);
      if (cached != null) {
        final age = await OfflineManager.getCacheAge(OfflineManager.feesKey);
        setState(() {
          _feesData = cached;
          _cacheAge = age;
          _isLoading = false;
        });
      } else {
        throw Exception('No cached data available');
      }
    }
  } catch (e) {
    ErrorHandler.logError('Load fees', e);
    
    // Show user-friendly error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getModuleErrorMessage('Fees', e)),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: loadFeesData,
        ),
      ),
    );
    
    setState(() => _isLoading = false);
  }
}
```

### Example 3: Attendance Marking with Error Handling

```dart
Future<void> markAttendanceViaBLE() async {
  try {
    // EXISTING BLE LOGIC (UNCHANGED)
    // ... scan for beacons
    // ... validate signal strength
    // ... prepare attendance data
    
    // Submit to server with timeout
    await SafeFirebaseCall.setData(
      ref: FirebaseDatabase.instance.ref('attendance/$path'),
      value: attendanceData,
      timeout: ApiConfig.quickTimeout,
      context: 'Mark BLE attendance',
    );
    
    // Success - confirmed by server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Attendance marked successfully'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ErrorHandler.logError('BLE attendance', e);
    
    // Show attendance-specific error
    final message = ErrorHandler.getAttendanceErrorMessage(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    
    // If local queue exists, add to queue for later sync
    // (Only if local queue is already implemented)
  }
}
```

---

## ✅ Testing Checklist

### Network Testing

- [ ] Test with WiFi enabled
- [ ] Test with mobile data enabled
- [ ] Test in airplane mode (no connection)
- [ ] Test with poor/unstable connection
- [ ] Test switching between WiFi and mobile data

### Offline Behavior

- [ ] Dashboard shows cached data when offline
- [ ] All modules show cached data or friendly error
- [ ] Offline banner appears when connection lost
- [ ] Offline banner disappears when connection restored
- [ ] Pull-to-refresh works when back online

### Error Handling

- [ ] Server errors show user-friendly messages
- [ ] Timeouts trigger retry options
- [ ] Parse errors don't crash app
- [ ] Authentication errors prompt re-login
- [ ] Module failures don't affect other modules

### Attendance Safety

- [ ] BLE attendance shows error on network failure
- [ ] QR attendance shows error on network failure
- [ ] Never shows success without server confirmation
- [ ] Local queue works (if implemented)
- [ ] Attendance operations remain unchanged

### Cache Management

- [ ] Fresh data is cached after successful fetch
- [ ] Cache age is displayed correctly
- [ ] Cache clearing works in Settings
- [ ] Authentication data is never cleared with cache

---

## 🎯 Key Principles

1. **User-Friendly First:** Always show clear, actionable messages
2. **Graceful Degradation:** Modules fail independently
3. **Offline-Ready:** Cache data for offline viewing
4. **Attendance Priority:** Never break core attendance features
5. **No Silent Failures:** Always inform user of issues
6. **Safe Defaults:** Assume online if check fails
7. **Clear Communication:** Set accurate expectations

---

## 📞 Support

For questions or issues with offline/error handling implementation:
- Review this document
- Check implementation files in `lib/services/`, `lib/utils/`, `lib/widgets/`
- Test with network disabled to verify offline behavior
- Ensure attendance operations remain unchanged

---

**Document Version:** 1.0  
**Last Updated:** November 29, 2025  
**Status:** Implementation Complete ✅
