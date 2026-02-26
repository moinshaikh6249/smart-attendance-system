# BLE Attendance System - Complete Architecture

## Overview
This document describes the redesigned BLE-based attendance system where:
- **Teacher app** broadcasts a permanent BLE UUID (non-connectable, legacy mode)
- **Student app** continuously scans for teacher UUIDs and creates pending attendance requests
- **Teacher app** shows pending requests and can approve/reject them

## Firebase Realtime Database Structure

### 1. Teachers Node
```
teachers/
  {teacherId}/  (Firebase Auth UID)
    id: string
    email: string
    name: string
    bleUuid: string (128-bit UUID v4, permanent per teacher)
    createdAt: timestamp
    updatedAt: timestamp
```

**Example:**
```json
{
  "teachers": {
    "abc123xyz": {
      "id": "abc123xyz",
      "email": "teacher@rtccs.com",
      "name": "John Teacher",
      "bleUuid": "550e8400-e29b-41d4-a716-446655440000",
      "createdAt": 1705312200000,
      "updatedAt": 1705312200000
    }
  }
}
```

### 2. Pending Attendance Requests Node
```
pending_attendance_requests/
  {teacherId}/
    {requestId}/
      requestId: string
      studentUUID: string
      studentName: string
      teacherId: string
      teacherName: string
      schoolID: string
      classID: string
      subjectID: string
      date: string (yyyy-MM-dd)
      timestamp: number (ms since epoch)
      status: "pending" | "approved" | "rejected"
      approvedAt: number (optional)
      rejectedAt: number (optional)
```

**Example:**
```json
{
  "pending_attendance_requests": {
    "abc123xyz": {
      "req_001": {
        "requestId": "req_001",
        "studentUUID": "uuid_001",
        "studentName": "John Doe",
        "teacherId": "abc123xyz",
        "teacherName": "John Teacher",
        "schoolID": "school_001",
        "classID": "class_001",
        "subjectID": "subject_001",
        "date": "2024-01-15",
        "timestamp": 1705312200000,
        "status": "pending"
      }
    }
  }
}
```

### 3. Student Attendance Requests (for history)
```
student_attendance_requests/
  {studentUUID}/
    {requestId}/
      (same structure as pending_attendance_requests)
```

### 4. Existing Nodes (unchanged)
- `schools/`
- `classes/`
- `subjects/`
- `students/`
- `attendance/`
- `attendance_logs/`

## BLE Advertising & Scanning

### Teacher App (Advertiser)
- **Mode**: Non-connectable, legacy advertising
- **UUID Format**: 128-bit UUID v4 (permanent per teacher)
- **Advertisement Data**: 
  - Manufacturer ID: 1234
  - Manufacturer Data: 16 bytes (UUID as raw bytes)
- **Interval**: ~100ms (10Hz)
- **Behavior**: Continuously broadcasts until stopped

### Student App (Scanner)
- **Mode**: Continuous foreground scanning
- **Filter**: Only processes advertisements with manufacturer ID 1234
- **UUID Matching**: Compares detected UUID against known teacher UUIDs from Firebase
- **Behavior**: 
  - Scans indefinitely until stopped
  - Creates pending attendance request when matching UUID detected
  - Avoids duplicate detections (tracks detected UUIDs)

## Flow Diagram

```
┌─────────────────┐
│  Teacher Login  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Get/Create Teacher      │
│ Record with BLE UUID    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Select School/Class/    │
│ Subject                 │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Start BLE Advertising   │
│ (Broadcast UUID)        │
└────────┬────────────────┘
         │
         │ (BLE Advertisement)
         │
         ▼
┌─────────────────────────┐
│ Student App:            │
│ Continuous Scan         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Detect Teacher UUID     │
│ Match with Firebase     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Create Pending Request  │
│ in Firebase             │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Teacher App:            │
│ View Pending Requests   │
│ (Real-time stream)      │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Approve/Reject Request  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Create Final Attendance │
│ Record                  │
└─────────────────────────┘
```

## Android Permissions Required

### Teacher App
- `BLUETOOTH`
- `BLUETOOTH_ADVERTISE` (Android 12+)
- `BLUETOOTH_CONNECT` (Android 12+)
- `ACCESS_FINE_LOCATION` (required for BLE on Android)

### Student App
- `BLUETOOTH`
- `BLUETOOTH_SCAN` (Android 12+)
- `BLUETOOTH_CONNECT` (Android 12+)
- `ACCESS_FINE_LOCATION` (required for BLE on Android)

## Best Practices

### Battery Optimization
1. **Scan Interval**: Use continuous scanning but with reasonable intervals
2. **Foreground Service**: Consider using a foreground service for long-running scans
3. **Screen Wake Lock**: Keep screen on during active scanning (optional)

### Scan Performance
1. **UUID Filtering**: Pre-load teacher UUIDs from Firebase to filter efficiently
2. **Duplicate Prevention**: Track detected UUIDs to avoid creating duplicate requests
3. **RSSI Threshold**: Optionally filter by signal strength (e.g., only process if RSSI > -80 dBm)

### Security
1. **UUID Validation**: Verify detected UUID exists in Firebase before creating request
2. **Rate Limiting**: Prevent spam by limiting requests per student per session
3. **Time Window**: Only allow requests within class time window (optional)

## Firebase Security Rules

```json
{
  "rules": {
    "teachers": {
      ".read": "auth != null",
      ".write": "auth != null && $uid == auth.uid"
    },
    "pending_attendance_requests": {
      "$teacherId": {
        ".read": "auth != null && $teacherId == auth.uid",
        ".write": "auth != null"
      }
    },
    "student_attendance_requests": {
      "$studentUUID": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

## Implementation Checklist

### Admin/Teacher App
- [x] Create Teacher model with BLE UUID
- [x] Update FirebaseService with teacher management
- [x] Update BLE service to use permanent UUID
- [x] Update BLE broadcast screen
- [ ] Create pending attendance approval screen
- [ ] Add real-time stream for pending requests

### Student App
- [x] Update BLE service for continuous scanning
- [x] Add UUID filtering logic
- [x] Update FirebaseService with teacher lookup
- [ ] Update attendance screen for continuous scanning
- [ ] Add pending request creation UI
- [ ] Add teacher detection notification

### Firebase Setup
- [ ] Update security rules
- [ ] Create sample teacher records
- [ ] Test UUID generation and storage

