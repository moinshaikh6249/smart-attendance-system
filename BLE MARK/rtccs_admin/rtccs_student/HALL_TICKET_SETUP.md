# 🎫 Hall Ticket / Admit Card Module Setup Guide

This guide explains how to set up and use the **Hall Ticket / Admit Card** module in the RTCCS Student App.

## Overview

The Hall Ticket module provides read-only access to examination hall tickets / admit cards including:
- Student details (Name, Enrollment No., PRN, Seat Number)
- Exam details (Name, Center, Dates)
- Program and semester information
- View/Download hall ticket PDF
- Offline access to cached hall tickets

This module is **optional**, **independent**, and **does not affect attendance or BLE/QR logic**.

---

## Features

### Core Features
- ✅ View hall ticket details
- ✅ Display student information (name, enrollment, PRN, seat)
- ✅ Show exam details (name, center, dates)
- ✅ Download/View PDF hall ticket
- ✅ Open PDF in external viewer
- ✅ Handle "not yet released" state gracefully
- ✅ Offline support with caching
- ✅ Pull-to-refresh for latest data
- ✅ Module guard prevents unauthorized access
- ✅ Error handling with retry mechanism
- ✅ Security: Students see only their own hall ticket

### Smart Handling
- **Released**: Show details + download button
- **Not Released**: Show "Not yet released" message
- **No Internet + Cached**: Show cached data with offline indicator
- **No Internet + No Cache**: Show error message
- **File Not Found**: Safe error handling, no crash

---

## Firebase Realtime Database Structure

### Data Structure

```
schools/
  {schoolId}/
    students/
      {studentUUID}/
        hallTicket/
          studentName: string
          enrollmentNo: string
          prn: string (optional)
          seatNumber: string
          examName: string
          program: string
          semester: string
          examCenterName: string
          centerCode: string (optional)
          examDates: array of strings (YYYY-MM-DD)
          pdfUrl: string (optional)
          imageUrl: string (optional)
          isReleased: boolean
          releaseDate: string (ISO date, optional)
          additionalInfo: object (optional)
```

### Example Data

```json
{
  "schools": {
    "SCHOOL001": {
      "students": {
        "STU-2024-001": {
          "hallTicket": {
            "studentName": "John Doe",
            "enrollmentNo": "2024IT001",
            "prn": "PRN2024001",
            "seatNumber": "IT-125",
            "examName": "TY BSc IT Semester 5 Final Examination - November 2024",
            "program": "BSc Information Technology",
            "semester": "Semester 5",
            "examCenterName": "Main Examination Center, College Building",
            "centerCode": "CENTER-001",
            "examDates": [
              "2024-05-15",
              "2024-05-17",
              "2024-05-20",
              "2024-05-22",
              "2024-05-25",
              "2024-05-30"
            ],
            "pdfUrl": "https://example.com/hall-tickets/STU-2024-001.pdf",
            "imageUrl": null,
            "isReleased": true,
            "releaseDate": "2024-05-01T10:00:00Z",
            "additionalInfo": {
              "reportingTime": "09:30 AM",
              "examStartTime": "10:00 AM",
              "examDuration": "3 hours",
              "instructions": [
                "Bring College ID Card",
                "Bring Hall Ticket printout",
                "No mobile phones allowed",
                "Report 30 minutes early"
              ]
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
      hallTicket: true
```

**Enable via Firebase Console:**
1. Go to Firebase Realtime Database
2. Navigate to `featureFlags/modules/{schoolId}/`
3. Set `hallTicket: true`

**OR enable globally for all schools:**
```
featureFlags/
  modules/
    global/
      hallTicket: true
```

### Step 2: Add Hall Ticket Data

Use the Firebase Console or the provided setup script:

#### Option A: Manual Entry (Firebase Console)
1. Go to Firebase Realtime Database
2. Navigate to `schools/{schoolId}/students/{studentUUID}/`
3. Add `hallTicket` node with data (see structure above)

#### Option B: Using Node.js Script

Use the provided `setup_hall_ticket_data.js` script:

```bash
node setup_hall_ticket_data.js
```

The script will:
- Add sample hall ticket data
- Set dynamic exam dates (10 days from today)
- Mark as released (`isReleased: true`)
- Enable the feature flag automatically
- Include sample PDF URL (update with actual URL)

### Step 3: Upload PDF File

#### Option 1: Firebase Storage
```bash
# Upload PDF to Firebase Storage
gsutil cp hall-ticket.pdf gs://your-bucket/hall-tickets/STU-2024-001.pdf

# Get public URL and update pdfUrl in database
```

#### Option 2: External Server
- Host PDF on your server
- Update `pdfUrl` with direct download link
- Ensure URL is publicly accessible (with proper authentication if needed)

#### Option 3: Cloud Storage (AWS S3, Google Cloud, etc.)
- Upload to cloud storage
- Generate signed URL or public URL
- Update `pdfUrl` in Firebase

### Step 4: Security Rules

Add these security rules to Firebase:

```json
{
  "rules": {
    "schools": {
      "$schoolId": {
        "students": {
          "$studentUUID": {
            "hallTicket": {
              ".read": "auth != null && (
                root.child('schools').child($schoolId).child('students').child($studentUUID).child('uuid').val() === auth.uid ||
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
- Students can only read their own hall ticket
- URL cannot be modified to access other students' data (checked by UUID)
- Only admins can write/update hall ticket data
- Feature flags are readable by authenticated users
- Only system admins can modify feature flags

---

## Testing

### Test Module - Released State
1. Enable the module: `featureFlags/modules/{schoolId}/hallTicket: true`
2. Add sample hall ticket data with `isReleased: true`
3. Add a valid `pdfUrl`
4. Login to student app
5. Navigate to **More** → **Hall Ticket**
6. Verify:
   - ✅ Hall ticket details display
   - ✅ Student name, enrollment, PRN, seat number shown
   - ✅ Exam details shown (name, center, dates)
   - ✅ "View / Download Hall Ticket" button appears
   - ✅ Tapping button opens PDF
   - ✅ Pull-to-refresh works
   - ✅ Works offline (cached data)

### Test Module - Not Released State
1. Set `isReleased: false` in Firebase
2. Navigate to Hall Ticket screen
3. Verify:
   - ✅ Shows "Hall Ticket Not Yet Released" message
   - ✅ Shows appropriate icon and description
   - ✅ Refresh button available
   - ✅ No crash or error

### Test Error Scenarios
1. **No internet + no cache**: Should show error with retry button
2. **Timeout**: Should gracefully fallback to cached data
3. **Module disabled**: Should show "Hall ticket download is currently not available"
4. **PDF URL invalid**: Should show error message, no crash
5. **Empty data**: Should show "Not yet released" state
6. **Invalid URL format**: Should handle gracefully

### Test Security
1. **Student A logs in**: Can see only their hall ticket
2. **Student B logs in**: Can see only their hall ticket (different data)
3. **Unauthenticated user**: Cannot access hall ticket
4. **Force logout on auth failure**: Security rules enforce this

---

## Field Descriptions

### Required Fields
- **studentName**: Full name of the student
- **enrollmentNo**: College enrollment number
- **seatNumber**: Assigned seat/roll number for exam
- **examName**: Full examination name/title
- **program**: Course/program name (e.g., "BSc IT")
- **semester**: Current semester (e.g., "Semester 5")
- **examCenterName**: Full exam center name/address
- **examDates**: Array of exam dates in YYYY-MM-DD format
- **isReleased**: Boolean - whether hall ticket is released

### Optional Fields
- **prn**: Permanent Registration Number (if applicable)
- **centerCode**: Exam center code/identifier
- **pdfUrl**: Direct URL to PDF hall ticket file
- **imageUrl**: Alternative image URL if hall ticket is an image
- **releaseDate**: When hall ticket was released (ISO date string)
- **additionalInfo**: Object with extra information (reporting time, instructions, etc.)

### Important Notes
- **Either pdfUrl OR imageUrl must be provided** when `isReleased: true`
- **examDates** can be a single date or array of dates
- **additionalInfo** is flexible - add any custom fields needed

---

## Architecture

### Provider
- **HallTicketProvider**: Manages hall ticket data, caching, download state

### Screen
- **HallTicketScreen**: UI for viewing hall ticket details

### Services (Shared)
- **ModuleAvailabilityService**: Feature flag checking and module guard
- **ModuleErrorHandler**: Consistent error/loading/empty states

### Caching
- Uses **SharedPreferences** for offline support
- Cache key format: `hall_ticket_{schoolId}_{studentUUID}`
- Cache timestamp tracked for freshness
- PDF path cached separately: `hall_ticket_pdf_path_{schoolId}_{studentUUID}`

### Download Handling
- Uses `url_launcher` package to open PDF
- Opens in external application (PDF viewer, browser)
- Platform-specific handling (Android, iOS)
- Safe error handling if URL is invalid or file not found

---

## Troubleshooting

### Hall Ticket Not Loading
1. Check feature flag: `featureFlags/modules/{schoolId}/hallTicket` is `true`
2. Verify data exists at: `schools/{schoolId}/students/{studentUUID}/hallTicket`
3. Check `isReleased` is `true`
4. Check Firebase security rules allow read access
5. Look for errors in Flutter logs

### PDF Won't Open
1. Verify `pdfUrl` is a valid URL
2. Check URL is publicly accessible
3. Test URL in browser directly
4. Ensure device has PDF viewer app installed
5. Check internet connection

### Module Access Denied
1. Verify student is logged in
2. Check student's `schoolId` and `uuid` match data path
3. Ensure Firebase Auth token is valid
4. Check security rules allow student to read their own data

### Offline Data Not Working
1. Verify student loaded data at least once while online
2. Check SharedPreferences is working (device storage permissions)
3. Clear app cache and retry: Settings → Apps → RTCCS Student → Clear Cache

### Security Issues
1. Ensure Firebase security rules are properly configured
2. Verify student UUID matches auth UID
3. Test with multiple student accounts
4. Check that URL modification doesn't expose other students' data

---

## Admin Notes

### Data Entry Recommendations
- Update student details to match actual records
- Use consistent date format: YYYY-MM-DD
- Test PDF URL before releasing hall ticket
- Set `isReleased: false` until ready to publish
- Include all exam dates in chronological order

### PDF Generation
For server-generated PDFs:
1. Generate PDF server-side (Python, Node.js, Java, etc.)
2. Upload to Firebase Storage or cloud storage
3. Generate download URL
4. Update `pdfUrl` in database
5. Set `isReleased: true`

### Bulk Operations
For multiple students:
1. Create PDFs for all students
2. Upload to storage with naming convention: `{studentUUID}.pdf`
3. Use Firebase Admin SDK to update database in batch
4. Set release date for all at once

### Release Process
```javascript
// Example: Release all hall tickets
const studentsRef = db.ref(`schools/${schoolId}/students`);
const snapshot = await studentsRef.get();

snapshot.forEach(studentSnapshot => {
  const studentUUID = studentSnapshot.key;
  studentSnapshot.ref.child('hallTicket/isReleased').set(true);
  studentSnapshot.ref.child('hallTicket/releaseDate').set(new Date().toISOString());
});
```

---

## Files Created/Modified

### New Files
1. `lib/providers/optional/hall_ticket_provider.dart` ✅
2. `lib/screens/optional/hall_ticket_screen.dart` ✅
3. `setup_hall_ticket_data.js` ✅
4. `HALL_TICKET_SETUP.md` (this file) ✅

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

✅ **Hall Ticket Module**: Complete with view, download, caching, offline support  
✅ **Feature Flag**: Remote control via Firebase (`hallTicket`)  
✅ **Module Guard**: Access control implemented  
✅ **Security**: Students see only their own hall ticket  
✅ **Error Handling**: Retry mechanisms and fallbacks  
✅ **Offline Support**: SharedPreferences caching  
✅ **Independent**: No impact on attendance or core features  
✅ **Safe Download**: Handles invalid URLs gracefully  

The module is production-ready and safe to deploy! 🚀

---

## Quick Reference

### Firebase Paths
```
Feature Flag: featureFlags/modules/{schoolId}/hallTicket
Data: schools/{schoolId}/students/{studentUUID}/hallTicket
Cache Key: hall_ticket_{schoolId}_{studentUUID}
PDF Cache: hall_ticket_pdf_path_{schoolId}_{studentUUID}
```

### Required vs Optional Fields
**Required:**
- studentName, enrollmentNo, seatNumber
- examName, program, semester
- examCenterName, examDates
- isReleased

**Optional:**
- prn, centerCode
- pdfUrl, imageUrl
- releaseDate, additionalInfo

### States
- **Released + Has PDF**: Show details + download button
- **Released + No PDF**: Show details, no download button
- **Not Released**: Show "Not yet released" message
- **Error**: Show error with retry
- **Loading**: Show loading spinner

### Date Format
- Date: `YYYY-MM-DD` (e.g., "2024-05-15")
- DateTime: ISO 8601 (e.g., "2024-05-01T10:00:00Z")

---

## Dependencies

### Required Packages
- `url_launcher` - For opening PDF URLs
- `shared_preferences` - For caching
- `firebase_database` - For data fetching
- `provider` - For state management
- `google_fonts` - For UI styling
- `intl` - For date formatting

All dependencies already included in `pubspec.yaml`.

---

**Setup Time**: ~10 minutes  
**Test Time**: ~5 minutes  
**PDF Generation**: Depends on admin process  
**Status**: Production Ready ✅
