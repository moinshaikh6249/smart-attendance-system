# 📅 Exam Timetable Module Setup Guide

This guide explains how to set up and use the **Exam Timetable** module in the RTCCS Student App.

## Overview

The Exam Timetable module provides read-only access to examination schedules including:
- Exam dates and timings
- Subject-wise exam details
- Exam types (Theory, Practical, Viva)
- Room/Center and seat number information
- Filtering and sorting capabilities

This module is **optional**, **independent**, and **does not affect attendance or BLE/QR logic**.

---

## Features

### Core Features
- ✅ View upcoming and past exams
- ✅ See next exam at a glance
- ✅ Filter by exam type (Theory, Practical, Viva)
- ✅ Filter to show only upcoming exams
- ✅ Date-wise grouping with "Today" and "Tomorrow" labels
- ✅ Sort by date and time automatically
- ✅ Display room/center information
- ✅ Show seat numbers (if available)
- ✅ Offline support with caching
- ✅ Pull-to-refresh for latest data
- ✅ Module guard prevents unauthorized access
- ✅ Error handling with retry mechanism

### Smart Filtering
- **All Exams**: Complete timetable
- **Upcoming Only**: Future exams only
- **By Type**: Theory, Practical, or Viva exams
- **Date Range**: Custom date filtering (optional)

---

## Firebase Realtime Database Structure

### Data Structure

```
schools/
  {schoolId}/
    students/
      {studentUUID}/
        examTimetable/
          {examId}: {
            "examName": "TY BSc IT Sem 5 Regular Exam",
            "subjectName": "Advanced Java Programming",
            "subjectCode": "USIT501",
            "examDate": "2024-05-15",        // YYYY-MM-DD format
            "startTime": "10:00",            // HH:MM format
            "endTime": "13:00",              // HH:MM format
            "examType": "Theory",            // Theory | Practical | Viva
            "roomOrCenter": "Room 301, Main Building",  // Optional
            "seatNumber": "IT-125"           // Optional
          }
```

### Example Data

```json
{
  "schools": {
    "SCHOOL001": {
      "students": {
        "STU-2024-001": {
          "examTimetable": {
            "EXAM001": {
              "examName": "TY BSc IT Sem 5 Regular Exam",
              "subjectName": "Advanced Java Programming",
              "subjectCode": "USIT501",
              "examDate": "2024-05-15",
              "startTime": "10:00",
              "endTime": "13:00",
              "examType": "Theory",
              "roomOrCenter": "Room 301, Main Building",
              "seatNumber": "IT-125"
            },
            "EXAM002": {
              "examName": "TY BSc IT Sem 5 Regular Exam",
              "subjectCode": "USIT502",
              "subjectName": "Internet of Things",
              "examDate": "2024-05-17",
              "startTime": "10:00",
              "endTime": "13:00",
              "examType": "Theory",
              "roomOrCenter": "Room 301, Main Building",
              "seatNumber": "IT-125"
            },
            "EXAM003": {
              "examName": "TY BSc IT Sem 5 Regular Exam",
              "subjectName": "Network Security",
              "subjectCode": "USIT503",
              "examDate": "2024-05-20",
              "startTime": "10:00",
              "endTime": "13:00",
              "examType": "Theory",
              "roomOrCenter": "Room 302, Main Building",
              "seatNumber": "IT-125"
            },
            "EXAM004": {
              "examName": "TY BSc IT Sem 5 Practical Exam",
              "subjectName": "Advanced Java Programming Lab",
              "subjectCode": "USITP501",
              "examDate": "2024-05-22",
              "startTime": "14:00",
              "endTime": "17:00",
              "examType": "Practical",
              "roomOrCenter": "Computer Lab 1",
              "seatNumber": "PC-25"
            },
            "EXAM005": {
              "examName": "TY BSc IT Sem 5 Practical Exam",
              "subjectName": "IoT Lab",
              "subjectCode": "USITP502",
              "examDate": "2024-05-24",
              "startTime": "14:00",
              "endTime": "17:00",
              "examType": "Practical",
              "roomOrCenter": "IoT Lab, 4th Floor",
              "seatNumber": "WS-12"
            },
            "EXAM006": {
              "examName": "TY BSc IT Sem 5 Viva",
              "subjectName": "Project Viva",
              "subjectCode": "USIT5P1",
              "examDate": "2024-05-27",
              "startTime": "09:00",
              "endTime": "12:00",
              "examType": "Viva",
              "roomOrCenter": "Conference Room",
              "seatNumber": null
            }
          }
        }
      }
    }
  }
}
```

---

## Setup Steps

### Step 1: Enable Module via Firebase

The module is controlled by a **remote feature flag** in Firebase Realtime Database:

```
featureFlags/
  modules/
    {schoolId}/
      examTimetable: true
```

**Enable via Firebase Console:**
1. Go to Firebase Realtime Database
2. Navigate to `featureFlags/modules/{schoolId}/`
3. Set `examTimetable: true`

**OR enable globally for all schools:**
```
featureFlags/
  modules/
    global/
      examTimetable: true
```

### Step 2: Add Exam Timetable Data

Use the Firebase Console or the provided setup script:

#### Option A: Manual Entry (Firebase Console)
1. Go to Firebase Realtime Database
2. Navigate to `schools/{schoolId}/students/{studentUUID}/`
3. Add `examTimetable` node with exam entries (see structure above)

#### Option B: Using Node.js Script

Use the provided `setup_exam_timetable_data.js` script:

```bash
node setup_exam_timetable_data.js
```

The script will:
- Add 6 sample exam entries (Theory, Practical, Viva)
- Set different dates (upcoming and past)
- Include room/center and seat number details
- Enable the feature flag automatically

### Step 3: Security Rules

Add these security rules to Firebase:

```json
{
  "rules": {
    "schools": {
      "$schoolId": {
        "students": {
          "$studentUUID": {
            "examTimetable": {
              ".read": "auth != null && (
                data.parent().child('uuid').val() === auth.uid ||
                root.child('schools').child($schoolId).child('admins').child(auth.uid).exists()
              )",
              ".write": "auth != null && root.child('schools').child($schoolId).child('admins').child(auth.uid).exists()"
            }
          }
        }
      }
    },
    "featureFlags": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
    }
  }
}
```

**Security Notes:**
- Students can only read their own exam timetable
- Only admins can write/update exam data
- Feature flags are readable by authenticated users
- Only system admins can modify feature flags

---

## Testing

### Test Module
1. Enable the module: `featureFlags/modules/{schoolId}/examTimetable: true`
2. Add sample exam data (see above)
3. Login to student app
4. Navigate to **More** → **Exam Time Table**
5. Verify:
   - ✅ Exams load successfully
   - ✅ "Next Exam" card displays at top (if upcoming exams exist)
   - ✅ Exams grouped by date
   - ✅ "Today" and "Tomorrow" labels show correctly
   - ✅ Can filter by exam type
   - ✅ "Upcoming Only" filter works
   - ✅ Pull-to-refresh works
   - ✅ Works offline (cached data)
   - ✅ Module guard blocks if disabled

### Test Filters
1. Tap filter icon (top-right)
2. Select "Upcoming Only"
   - ✅ Only future exams shown
3. Select "Theory"
   - ✅ Only theory exams shown
4. Select "Practical"
   - ✅ Only practical exams shown
5. Select "Viva"
   - ✅ Only viva exams shown
6. Select "All Exams"
   - ✅ All exams shown again

### Test Error Scenarios
1. **No internet + no cache**: Should show error with retry button
2. **Timeout**: Should gracefully fallback to cached data
3. **Module disabled**: Should show "Exam timetable is currently not available"
4. **Empty data**: Should show "No exam timetable available right now"
5. **No matching filter**: Should show "No exams match this filter"

---

## Field Descriptions

### Required Fields
- **examName**: Name of the examination series (e.g., "Semester 5 Final Exam")
- **subjectName**: Full subject name
- **subjectCode**: Subject code/identifier
- **examDate**: Date in YYYY-MM-DD format
- **startTime**: Start time in HH:MM format (24-hour)
- **endTime**: End time in HH:MM format (24-hour)
- **examType**: Must be one of: "Theory", "Practical", "Viva"

### Optional Fields
- **roomOrCenter**: Exam venue/room/center details
- **seatNumber**: Student's seat/roll number for the exam

---

## Architecture

### Provider
- **ExamTimetableProvider**: Manages exam data, caching, filtering, sorting

### Screen
- **ExamTimetableScreen**: UI for viewing exam timetable

### Services (Shared)
- **ModuleAvailabilityService**: Feature flag checking and module guard
- **ModuleErrorHandler**: Consistent error/loading/empty states

### Caching
- Uses **SharedPreferences** for offline support
- Cache key format: `exam_timetable_{schoolId}_{studentUUID}`
- Cache timestamp tracked for freshness

---

## Key Features

### Smart Sorting
Exams are automatically sorted:
1. **Primary**: By exam date (ascending)
2. **Secondary**: By start time (ascending)

### Date Headers
Exams are grouped by date with smart labels:
- **Today**: Exams happening today
- **Tomorrow**: Exams happening tomorrow
- **Full Date**: For other dates (e.g., "Monday, May 15, 2024")

### Type-Based Badges
Each exam displays a color-coded badge:
- **Theory**: Blue badge with book icon
- **Practical**: Orange badge with science icon
- **Viva**: Purple badge with mic icon

### Next Exam Card
If upcoming exams exist, a prominent "Next Exam" card shows:
- Subject name
- Date and time
- Highlighted in green for visibility

---

## Troubleshooting

### Exam Timetable Not Loading
1. Check feature flag: `featureFlags/modules/{schoolId}/examTimetable` is `true`
2. Verify data exists at: `schools/{schoolId}/students/{studentUUID}/examTimetable`
3. Check Firebase security rules allow read access
4. Look for errors in Flutter logs

### Module Access Denied
1. Verify student is logged in
2. Check student's `schoolId` matches feature flag path
3. Ensure Firebase Auth token is valid
4. Check security rules allow student to read their own data

### Offline Data Not Working
1. Verify student loaded data at least once while online
2. Check SharedPreferences is working (device storage permissions)
3. Clear app cache and retry: Settings → Apps → RTCCS Student → Clear Cache

### Filters Not Working
1. Ensure `examType` field matches exactly: "Theory", "Practical", or "Viva" (case-sensitive)
2. Check date format is correct: YYYY-MM-DD
3. Verify time format is correct: HH:MM (24-hour)

---

## Admin Notes

### Data Entry Recommendations
- Use consistent `examType` values: "Theory", "Practical", "Viva" (exact casing)
- Always use YYYY-MM-DD format for dates
- Use 24-hour format for times (e.g., "14:00" not "2:00 PM")
- Include `roomOrCenter` for better student experience
- `seatNumber` can be optional if managed in Hall Ticket module

### Bulk Data Entry
For bulk import, structure data as JSON:
```json
{
  "EXAM001": { "examName": "...", "subjectName": "...", ... },
  "EXAM002": { "examName": "...", "subjectName": "...", ... },
  ...
}
```

Then import via Firebase Console:
1. Navigate to exam timetable path
2. Click "⋮" → "Import JSON"
3. Paste JSON data
4. Click "Import"

---

## Files Created/Modified

### New Files
1. `lib/providers/optional/exam_timetable_provider.dart` ✅
2. `lib/screens/optional/exam_timetable_screen.dart` ✅
3. `setup_exam_timetable_data.js` ✅
4. `EXAM_TIMETABLE_SETUP.md` (this file) ✅

### Modified Files
1. `lib/main.dart` - Added provider and route ✅

### Existing Files (Unchanged)
- Core attendance logic (BLE, QR)
- Dashboard screen
- Feature flags config
- Module availability service
- Error handler service
- Module placeholders (placeholder already exists)

---

## Summary

✅ **Exam Timetable Module**: Complete with filtering, sorting, caching, offline support  
✅ **Feature Flag**: Remote control via Firebase (`examTimetable`)  
✅ **Module Guard**: Access control implemented  
✅ **Error Handling**: Retry mechanisms and fallbacks  
✅ **Offline Support**: SharedPreferences caching  
✅ **Independent**: No impact on attendance or core features  
✅ **Security**: Students see only their own data  

The module is production-ready and safe to deploy! 🚀

---

## Quick Reference

### Firebase Paths
```
Feature Flag: featureFlags/modules/{schoolId}/examTimetable
Data: schools/{schoolId}/students/{studentUUID}/examTimetable
Cache Key: exam_timetable_{schoolId}_{studentUUID}
```

### Exam Types
- `Theory` - Written exams
- `Practical` - Lab/practical exams
- `Viva` - Oral exams/viva voce

### Date Formats
- Date: `YYYY-MM-DD` (e.g., "2024-05-15")
- Time: `HH:MM` (e.g., "10:00", "14:30")

### Filter Options
- `all` - All exams
- `upcoming` - Future exams only
- `theory` - Theory exams
- `practical` - Practical exams
- `viva` - Viva exams

---

**Setup Time**: ~5 minutes  
**Test Time**: ~5 minutes  
**Status**: Production Ready ✅
