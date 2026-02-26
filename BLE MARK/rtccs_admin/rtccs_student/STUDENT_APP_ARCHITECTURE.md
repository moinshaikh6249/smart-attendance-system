# BLE Mark Student App - Architecture & Feature Modules

## Overview
This document defines the high-level architecture, feature modules, and navigation structure for the BLE Mark Student app. The design ensures **core attendance features remain untouched** while allowing **optional modules to be safely enabled/disabled** based on backend availability.

---

## Design Principles

### 1. **Core-First Architecture**
- Core attendance features (BLE/QR scanning, attendance viewing) are **completely independent**
- Optional modules cannot break core functionality
- Feature flags control optional module availability

### 2. **Graceful Degradation**
- App works perfectly with only core modules
- Optional modules fail silently if backend unavailable
- Clear user feedback when features are disabled

### 3. **Zero Breaking Changes**
- Existing BLE and QR attendance logic remains **100% unchanged**
- Current navigation flow preserved for core features
- Dashboard acts as central hub for all features

---

## Module Structure

```
┌─────────────────────────────────────────────────────────┐
│                    STUDENT APP                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │          CORE MODULES (MANDATORY)               │   │
│  │  ✓ Always Available                             │   │
│  │  ✓ No Dependencies on Optional Modules          │   │
│  │  ✓ Must Never Break                             │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │       OPTIONAL MODULES (FEATURE-FLAGGED)        │   │
│  │  ○ Disabled if Backend Unavailable              │   │
│  │  ○ Cannot Break Core Modules                    │   │
│  │  ○ Graceful Error Handling                      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 1. CORE MODULES (ALWAYS AVAILABLE)

These modules are **mandatory** and must always work, even if all optional modules fail.

### 1.1 Dashboard (Hub)
**Purpose:** Central navigation and student information display

**Features:**
- **Student Info Card**
  - Name, UUID (masked for security)
  - Class, Subject
  - Profile photo (if available)
  - Attendance percentage (quick view)

- **Quick Actions (Shortcuts)**
  - 🎯 Mark Attendance (BLE + QR options)
  - 📊 View Attendance Records
  - 📡 BLE Diagnostic Scan
  - 👤 My Profile

- **Recent Activity**
  - Last 5 attendance records
  - Date, time, method (BLE/QR), admin name
  - Status indicators (present/absent)

**Implementation:**
```dart
// File: lib/screens/dashboard_screen.dart
// Status: EXISTS - needs enhancement for module shortcuts
// Dependencies: NONE (core only)
```

**Rules:**
- ✅ Must work without any optional modules
- ✅ Shows only available features (hides disabled modules)
- ✅ Recent activity sourced from core attendance data only

---

### 1.2 Mark Attendance
**Purpose:** Record attendance via BLE or QR code

**Features:**
- **BLE Scanning**
  - Scan for admin/teacher BLE beacon
  - UUID validation and handshake
  - Auto-submit attendance record
  - Visual feedback (scanning, success, error)

- **QR Code Scanning**
  - Scan admin-generated QR code
  - Validate QR data format
  - Auto-submit attendance record
  - Camera permission handling

- **Attendance Submission**
  - Save to Firebase: `attendance/{schoolID}/{classID}/{subjectID}/{date}/{studentUUID}`
  - Record: timestamp, method (BLE/QR), admin UUID, location (if enabled)
  - Local caching if offline
  - Retry mechanism for network failures

**Implementation:**
```dart
// Files:
// - lib/services/ble_service.dart (EXISTS - DO NOT CHANGE)
// - lib/services/qr_service.dart (EXISTS - DO NOT CHANGE)
// - lib/providers/attendance_provider.dart (EXISTS - enhanced for caching)
// - Called from Dashboard via _markAttendance() method
```

**Rules:**
- ✅ **ZERO CHANGES to existing BLE/QR logic**
- ✅ Only UI enhancements allowed (better feedback, animations)
- ✅ Must work offline with local caching
- ✅ No dependencies on optional modules

---

### 1.3 View Attendance
**Purpose:** Student views their own attendance history

**Features:**
- **Attendance List**
  - Date-wise attendance records (newest first)
  - Method badge (BLE/QR)
  - Admin/teacher name
  - Timestamp (formatted: "2 hours ago", "Yesterday 10:30 AM")
  - Subject and class info

- **Statistics**
  - Total days present
  - Total days absent
  - Attendance percentage (with color coding)
  - Monthly breakdown (if data available)

- **Filters**
  - Date range picker (last 7 days, last 30 days, custom)
  - Subject filter (if student has multiple subjects)
  - Method filter (BLE only, QR only, all)

**Implementation:**
```dart
// Files:
// - lib/screens/attendance_screen.dart (EXISTS - needs enhancement)
// - lib/screens/history_screen.dart (EXISTS - can be merged)
// - lib/providers/attendance_provider.dart (EXISTS)
```

**Rules:**
- ✅ Shows only student's own records (security)
- ✅ Works with cached data if offline
- ✅ No dependencies on optional modules

---

### 1.4 BLE Scan/Diagnostics
**Purpose:** Test BLE connectivity and troubleshoot issues

**Features:**
- **Scan Status**
  - Bluetooth enabled/disabled
  - Permission status (location, Bluetooth)
  - Device broadcasting capability

- **Device Discovery**
  - Scan for nearby BLE devices
  - Show admin/teacher devices
  - Signal strength (RSSI)
  - UUID validation

- **Diagnostics**
  - Test UUID format
  - Check Firebase connectivity
  - Verify student registration
  - Export logs for support

**Implementation:**
```dart
// Files:
// - lib/screens/ble_diagnostics_screen.dart (EXISTS)
// - lib/screens/ble_broadcast_page.dart (EXISTS)
// - lib/services/ble_service.dart (EXISTS - DO NOT CHANGE)
```

**Rules:**
- ✅ Read-only diagnostic tool
- ✅ Cannot modify BLE service logic
- ✅ Helps students troubleshoot independently

---

### 1.5 Student Profile (Core)
**Purpose:** View and edit basic student information

**Features:**
- **Profile Display**
  - Full name, UUID
  - Class, subject, school
  - Profile photo
  - Registration date

- **Editable Fields**
  - Profile photo (upload from gallery)
  - Display name (optional nickname)
  - Contact email (for notifications)
  - Emergency contact (optional)

- **Actions**
  - Change password
  - Re-register (generate new UUID if needed)
  - Logout

**Implementation:**
```dart
// Files:
// - lib/screens/profile_screen.dart (EXISTS - needs enhancement)
// - lib/providers/profile_provider.dart (EXISTS)
// - lib/services/photo_service.dart (EXISTS)
```

**Rules:**
- ✅ Core fields (name, UUID, class, subject) read-only after registration
- ✅ Only cosmetic fields (photo, nickname) editable
- ✅ Cannot change school/class without admin approval

---

## 2. OPTIONAL MODULES (FEATURE-FLAGGED)

These modules are **optional** and can be safely disabled if backend support is unavailable.

### Feature Flag System

**Implementation:**
```dart
// File: lib/config/feature_flags.dart (NEW)

class FeatureFlags {
  static const bool enableTimetable = false;
  static const bool enableFees = false;
  static const bool enableResults = false;
  static const bool enableAnnouncements = false;
  static const bool enableLibrary = false;
  static const bool enableLeaveRequests = false;
  
  // Dynamic flags (from Firebase Remote Config)
  static Future<Map<String, bool>> loadRemoteFlags() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('app_config/student_features')
          .get();
      
      if (snapshot.exists) {
        return Map<String, bool>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Failed to load feature flags: $e');
    }
    
    // Return defaults if remote config fails
    return {
      'timetable': enableTimetable,
      'fees': enableFees,
      'results': enableResults,
      'announcements': enableAnnouncements,
      'library': enableLibrary,
      'leaveRequests': enableLeaveRequests,
    };
  }
}
```

---

### 2.1 Timetable Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** View class schedule and upcoming lectures

**Features:**
- **Weekly Timetable**
  - Day-wise schedule (Monday to Saturday)
  - Subject name, teacher, room number
  - Time slots (e.g., 9:00 AM - 10:00 AM)
  - Current class highlighted

- **Today's Schedule**
  - Quick view of today's classes
  - Next class countdown
  - Free periods highlighted

**Backend Required:**
```
Firebase Path: timetable/{schoolID}/{classID}
Structure: {
  "monday": [
    {
      "slot": "09:00-10:00",
      "subject": "Mathematics",
      "teacher": "John Doe",
      "room": "A-101"
    }
  ]
}
```

**Failure Handling:**
- If Firebase path missing → Hide module from dashboard
- If data incomplete → Show "Timetable unavailable" message
- Never crashes core app

---

### 2.2 Fees Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** View fee structure, payment status, receipts

**Features:**
- **Fee Summary**
  - Total fee amount
  - Paid amount
  - Outstanding balance
  - Payment deadline

- **Payment History**
  - Date, amount, mode (online/cash)
  - Receipt download (PDF)
  - Transaction ID

- **Installments**
  - Upcoming installments
  - Due dates
  - Overdue warnings

**Backend Required:**
```
Firebase Path: fees/{schoolID}/students/{studentUUID}
Structure: {
  "totalFee": 50000,
  "paidAmount": 30000,
  "payments": [
    {
      "date": "2025-08-15",
      "amount": 10000,
      "mode": "online",
      "receiptUrl": "..."
    }
  ]
}
```

**Failure Handling:**
- If path missing → Hide from dashboard
- If no payment records → Show "No payment history"
- Read-only (no payment processing in app)

---

### 2.3 Results Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** View exam results, grades, and performance reports

**Features:**
- **Exam Results**
  - Subject-wise marks
  - Grade/percentage
  - Rank (class/school)
  - Pass/fail status

- **Performance Trends**
  - Graph: marks over time
  - Subject comparison
  - Attendance vs performance correlation

- **Report Cards**
  - Download PDF report cards
  - Semester-wise results
  - Teacher remarks

**Backend Required:**
```
Firebase Path: results/{schoolID}/{classID}/students/{studentUUID}
Structure: {
  "semester1": {
    "mathematics": {
      "marks": 85,
      "grade": "A",
      "maxMarks": 100
    }
  }
}
```

**Failure Handling:**
- If no results published → Show "Results not available yet"
- If exam data incomplete → Show partial results with disclaimer
- Never affects attendance features

---

### 2.4 Announcements Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** Receive school/class announcements and notifications

**Features:**
- **Announcement Feed**
  - Latest announcements (newest first)
  - Category badges (urgent, general, event)
  - Read/unread status
  - Date and time

- **Filters**
  - School-wide announcements
  - Class-specific announcements
  - Subject-specific announcements

- **Push Notifications**
  - Optional: notify on new announcements
  - Configurable in settings

**Backend Required:**
```
Firebase Path: announcements/{schoolID}
Structure: {
  "global": [...],
  "classes/{classID}": [...],
  "subjects/{subjectID}": [...]
}
```

**Failure Handling:**
- If no announcements → Show "No announcements"
- If Firebase offline → Show cached announcements
- Notification failure → Silent (no crash)

---

### 2.5 Library Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** View issued books, due dates, library fines

**Features:**
- **Issued Books**
  - Book name, author, ISBN
  - Issue date, due date
  - Overdue warnings

- **Return Reminders**
  - Days until due
  - Late fee calculation

- **Library Catalog**
  - Search available books
  - Check availability (optional)

**Backend Required:**
```
Firebase Path: library/{schoolID}/students/{studentUUID}/issued_books
```

**Failure Handling:**
- If no library data → Hide module
- If no books issued → Show "No books issued"

---

### 2.6 Leave Requests Module (Optional)
**Status:** 🟡 Disabled by default

**Purpose:** Submit leave applications and track status

**Features:**
- **Request Leave**
  - Date range picker
  - Reason (dropdown + custom text)
  - Attach document (optional)

- **Leave History**
  - Pending, approved, rejected status
  - Approval by (admin/teacher name)
  - Rejection reason

**Backend Required:**
```
Firebase Path: leave_requests/{schoolID}/{studentUUID}
```

**Failure Handling:**
- If submission fails → Save draft locally
- If backend unavailable → Disable submit button
- If no leaves → Show "No leave requests"

---

## 3. Navigation Structure

### App Navigation Flow

```
┌──────────────────────┐
│   Splash Screen      │
│   (Auto-navigate)    │
└──────────────────────┘
          │
          ▼
┌──────────────────────┐
│   Welcome Screen     │
│   • Login            │───────► Login Screen
│   • Register         │───────► Registration
│   • Recover UUID     │───────► Recovery
└──────────────────────┘
          │
          ▼
┌──────────────────────┐
│      DASHBOARD       │◄───────── (App Home)
│  (Central Hub)       │
└──────────────────────┘
          │
          ├───► Mark Attendance (BLE/QR Modal)
          ├───► View Attendance Screen
          ├───► BLE Diagnostics Screen
          ├───► Student Profile Screen
          │
          ├───► [OPTIONAL: Timetable]
          ├───► [OPTIONAL: Fees]
          ├───► [OPTIONAL: Results]
          ├───► [OPTIONAL: Announcements]
          ├───► [OPTIONAL: Library]
          └───► [OPTIONAL: Leave Requests]
```

### Bottom Navigation (Dashboard Enhancement)

**Proposed Design:**
```
┌─────────────────────────────────────────┐
│          Dashboard Screen                │
│                                          │
│  [Student Info Card]                     │
│  [Quick Actions Grid]                    │
│  [Recent Activity]                       │
│  [Optional Module Cards]                 │
│                                          │
└─────────────────────────────────────────┘
           Bottom Navigation
┌────────┬────────┬────────┬────────────┐
│  Home  │ Attend │  More  │  Profile   │
└────────┴────────┴────────┴────────────┘
```

**Tab Definitions:**
1. **🏠 Home:** Dashboard (current screen)
2. **✓ Attend:** Direct shortcut to Mark Attendance modal
3. **≡ More:** Optional modules + settings
4. **👤 Profile:** Student profile + logout

**Implementation:**
```dart
// File: lib/screens/main_navigation_screen.dart (NEW)

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),      // Home
    AttendanceScreen(),     // View Attendance
    MoreScreen(),           // Optional modules
    ProfileScreen(),        // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            // Show Mark Attendance modal instead of navigating
            _showMarkAttendanceModal();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attend'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'More'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showMarkAttendanceModal() {
    // Existing _markAttendance() logic from DashboardScreen
  }
}
```

---

### "More" Screen (Optional Modules Hub)

```dart
// File: lib/screens/more_screen.dart (NEW)

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: FutureBuilder<Map<String, bool>>(
        future: FeatureFlags.loadRemoteFlags(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final flags = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (flags['timetable'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Timetable',
                  subtitle: 'View class schedule',
                  onTap: () => Navigator.pushNamed(context, '/timetable'),
                ),
              
              if (flags['fees'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Fees',
                  subtitle: 'Payment status & receipts',
                  onTap: () => Navigator.pushNamed(context, '/fees'),
                ),
              
              if (flags['results'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Results',
                  subtitle: 'Exam marks & grades',
                  onTap: () => Navigator.pushNamed(context, '/results'),
                ),
              
              if (flags['announcements'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.notifications,
                  title: 'Announcements',
                  subtitle: 'School & class updates',
                  onTap: () => Navigator.pushNamed(context, '/announcements'),
                ),
              
              if (flags['library'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.book,
                  title: 'Library',
                  subtitle: 'Issued books & due dates',
                  onTap: () => Navigator.pushNamed(context, '/library'),
                ),
              
              if (flags['leaveRequests'] == true)
                _buildModuleTile(
                  context,
                  icon: Icons.event_busy,
                  title: 'Leave Requests',
                  subtitle: 'Apply for leave',
                  onTap: () => Navigator.pushNamed(context, '/leave'),
                ),

              const Divider(height: 32),

              // App Settings (Always Available)
              _buildModuleTile(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences & notifications',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),

              _buildModuleTile(
                context,
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'FAQs & contact support',
                onTap: () => Navigator.pushNamed(context, '/help'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue.shade600),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 4. Implementation Strategy

### Phase 1: Core Module Stabilization (Week 1)
✅ **No changes to existing BLE/QR logic**
- Enhance Dashboard UI with better shortcuts
- Improve attendance history screen (filters, stats)
- Add profile photo upload
- Implement bottom navigation

### Phase 2: Feature Flag System (Week 1-2)
- Create `lib/config/feature_flags.dart`
- Implement remote config from Firebase
- Build "More" screen with dynamic modules
- Add graceful error handling

### Phase 3: Optional Module Scaffolding (Week 2-3)
- Create placeholder screens for each optional module
- Implement backend availability checks
- Add "Feature unavailable" states
- Test with partial backend support

### Phase 4: Optional Module Implementation (Week 3+)
- Implement modules one by one based on priority:
  1. Announcements (easiest, high value)
  2. Timetable (moderate complexity)
  3. Results (moderate complexity)
  4. Fees (requires payment gateway)
  5. Library (low priority)
  6. Leave Requests (low priority)

---

## 5. Safety Mechanisms

### 5.1 Core Module Protection
```dart
// Rule: Optional modules CANNOT import core services

// ❌ FORBIDDEN in optional modules:
import '../services/ble_service.dart';
import '../services/qr_service.dart';
import '../providers/attendance_provider.dart';

// ✅ ALLOWED:
import '../config/feature_flags.dart';
import '../providers/announcements_provider.dart'; // Optional provider
```

### 5.2 Error Isolation
```dart
// Wrapper for optional module navigation
void navigateToOptionalModule(BuildContext context, String route) {
  try {
    Navigator.pushNamed(context, route);
  } catch (e) {
    // Log error but don't crash app
    print('Failed to load module: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is temporarily unavailable'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
```

### 5.3 Backend Availability Check
```dart
// Check if backend path exists before showing module
Future<bool> checkModuleAvailability(String moduleName) async {
  try {
    final snapshot = await FirebaseDatabase.instance
        .ref('app_config/student_features/$moduleName')
        .get();
    return snapshot.exists && snapshot.value == true;
  } catch (e) {
    return false; // Fail-safe: disable if check fails
  }
}
```

---

## 6. Testing Checklist

### Core Module Tests
- [ ] Dashboard loads with only core modules (all optional disabled)
- [ ] BLE attendance works without any optional module
- [ ] QR attendance works without any optional module
- [ ] Attendance history shows correctly with zero dependencies
- [ ] Profile editing works independently

### Feature Flag Tests
- [ ] App works with all flags = false
- [ ] App works with all flags = true
- [ ] App works with random subset of flags enabled
- [ ] Remote config failure defaults to all disabled
- [ ] Flag changes reflect immediately (no restart needed)

### Error Handling Tests
- [ ] Optional module with missing backend → Shows "unavailable" message
- [ ] Optional module with corrupt data → Shows error, doesn't crash
- [ ] Network failure during optional module load → Shows retry option
- [ ] Core modules unaffected by optional module errors

---

## 7. File Structure

```
lib/
├── config/
│   ├── feature_flags.dart          # NEW: Feature flag system
│   └── app_config.dart             # NEW: App-wide constants
│
├── screens/
│   ├── dashboard_screen.dart       # MODIFY: Enhanced with module shortcuts
│   ├── main_navigation_screen.dart # NEW: Bottom navigation wrapper
│   ├── more_screen.dart            # NEW: Optional modules hub
│   │
│   ├── core/                       # Core modules (always available)
│   │   ├── attendance_screen.dart  # EXISTS: View attendance
│   │   ├── history_screen.dart     # EXISTS: Can merge with attendance
│   │   ├── profile_screen.dart     # EXISTS: Student profile
│   │   └── ble_diagnostics_screen.dart # EXISTS: BLE testing
│   │
│   └── optional/                   # Optional modules (feature-flagged)
│       ├── timetable_screen.dart   # NEW: Class schedule
│       ├── fees_screen.dart        # NEW: Fee management
│       ├── results_screen.dart     # NEW: Exam results
│       ├── announcements_screen.dart # NEW: Notifications
│       ├── library_screen.dart     # NEW: Library books
│       └── leave_screen.dart       # NEW: Leave requests
│
├── providers/
│   ├── attendance_provider.dart    # EXISTS: Core provider
│   ├── profile_provider.dart       # EXISTS: Core provider
│   │
│   └── optional/                   # Optional providers
│       ├── timetable_provider.dart # NEW
│       ├── fees_provider.dart      # NEW
│       ├── results_provider.dart   # NEW
│       └── announcements_provider.dart # NEW
│
├── services/
│   ├── ble_service.dart            # EXISTS: DO NOT MODIFY
│   ├── qr_service.dart             # EXISTS: DO NOT MODIFY
│   ├── firebase_service.dart       # EXISTS: Core operations only
│   │
│   └── optional/                   # Optional services
│       └── optional_modules_service.dart # NEW: Backend availability checks
│
└── widgets/
    ├── module_card.dart            # NEW: Reusable module card
    ├── feature_unavailable.dart    # NEW: Disabled module placeholder
    └── attendance_card.dart        # EXISTS: Reusable attendance display
```

---

## 8. Firebase Structure (Backend Requirements)

### Core Data (Always Available)
```
attendance/
  {schoolID}/
    {classID}/
      {subjectID}/
        {date}/
          {studentUUID}: { ...attendance record... }

students/
  {schoolID}/
    {classID}/
      {subjectID}/
        {studentUUID}: { ...student profile... }
```

### Optional Module Data (Feature-Flagged)
```
app_config/
  student_features/
    timetable: true/false
    fees: true/false
    results: true/false
    announcements: true/false
    library: true/false
    leaveRequests: true/false

timetable/
  {schoolID}/
    {classID}/
      monday: [...]
      tuesday: [...]

fees/
  {schoolID}/
    students/
      {studentUUID}: { ...fee details... }

results/
  {schoolID}/
    {classID}/
      students/
        {studentUUID}: { ...exam results... }

announcements/
  {schoolID}/
    global: [...]
    classes/
      {classID}: [...]

library/
  {schoolID}/
    students/
      {studentUUID}/
        issued_books: [...]

leave_requests/
  {schoolID}/
    {studentUUID}: [...]
```

---

## 9. User Experience Flow

### Scenario 1: Student with Only Core Modules
1. **Login** → Dashboard shows:
   - Student info card
   - "Mark Attendance" button (prominent)
   - "View Attendance" button
   - Recent activity list
   - No optional module cards (hidden)

2. **Mark Attendance** → Modal with BLE/QR options
3. **View Attendance** → Full history with filters
4. **Profile** → Basic info + edit photo

**Result:** Clean, focused experience for attendance-only use

---

### Scenario 2: Student with All Modules Enabled
1. **Login** → Dashboard shows:
   - Student info card
   - Quick actions grid (4 buttons)
   - Recent activity
   - Scrollable module cards (Timetable, Fees, Results, etc.)

2. **Bottom Navigation:**
   - Home → Dashboard
   - Attend → Quick mark attendance
   - More → All optional modules
   - Profile → Full profile

**Result:** Rich feature set without overwhelming UI

---

### Scenario 3: Backend Partially Down
1. **Login** → Dashboard loads normally
2. **Timetable module unavailable** → Card shows:
   - Gray icon
   - "Timetable temporarily unavailable"
   - Tap to retry

3. **Core modules unaffected** → Attendance still works perfectly

**Result:** Graceful degradation, core functionality preserved

---

## 10. Summary

### ✅ Design Goals Achieved

1. **Core Modules Protected**
   - BLE/QR attendance logic untouched
   - Zero dependencies on optional modules
   - Isolated in separate service files

2. **Optional Modules Safely Disabled**
   - Feature flags control visibility
   - Backend availability checks
   - Graceful error handling
   - Never crash core app

3. **Scalable Architecture**
   - Easy to add new optional modules
   - Clear separation of concerns
   - Modular provider system
   - Maintainable codebase

4. **Excellent UX**
   - Bottom navigation for quick access
   - Dashboard as central hub
   - Clear visual hierarchy
   - Responsive to backend availability

---

## Next Steps

1. **Review & Approve Architecture** ✓
2. **Implement Phase 1 (Core Enhancements)**
3. **Implement Phase 2 (Feature Flags)**
4. **Build Optional Module Placeholders**
5. **Gradual Rollout of Optional Modules**

---

**Document Version:** 1.0  
**Last Updated:** November 28, 2025  
**Status:** 🟢 Ready for Implementation
