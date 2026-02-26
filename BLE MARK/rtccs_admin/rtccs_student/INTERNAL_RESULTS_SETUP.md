# Internal Marks & Results Module Setup Guide

This guide explains how to set up and use the **Internal Marks** and **Results** modules in the RTCCS Student App.

## Overview

These modules provide read-only access to:
- **Internal Marks**: Continuous assessment (IA1, IA2, Assignments, Practicals, etc.)
- **Results**: Semester exam results with SGPA/CGPA and subject grades

Both modules are **optional**, **independent**, and **do not affect attendance or BLE/QR logic**.

---

## Features

### Internal Marks Module
- ✅ View internal assessment marks by subject or component
- ✅ See IA1, IA2, Assignment, Practical marks separately
- ✅ Calculate overall percentage automatically
- ✅ Display total marks per subject
- ✅ Offline support with caching
- ✅ Pull-to-refresh for latest data
- ✅ Module guard prevents unauthorized access
- ✅ Error handling with retry

### Results Module
- ✅ View semester exam results
- ✅ Display SGPA, CGPA, and total credits earned
- ✅ Show subject-wise grades and grade points
- ✅ Pass/Fail/Absent status indicators
- ✅ Expandable semester cards with detailed subject results
- ✅ "Not Published" message for unreleased results
- ✅ Offline support with caching
- ✅ Pull-to-refresh for latest data
- ✅ Module guard prevents unauthorized access
- ✅ Error handling with retry

---

## Firebase Realtime Database Structure

### 1. Internal Marks Data Structure

```
schools/
  {schoolId}/
    students/
      {studentUUID}/
        internalMarks/
          {entryId}: {
            "subjectName": "Mathematics",
            "subjectCode": "MATH101",
            "examComponent": "IA1",  // IA1, IA2, Assignment, Practical, etc.
            "maxMarks": 25,
            "marksObtained": 22,
            "weightage": 20,  // Optional: weightage percentage
            "examDate": "2024-01-15"  // Optional
          }
```

**Example Data:**
```json
{
  "schools": {
    "SCHOOL001": {
      "students": {
        "STU-2024-001": {
          "internalMarks": {
            "MARK001": {
              "subjectName": "Mathematics",
              "subjectCode": "MATH101",
              "examComponent": "IA1",
              "maxMarks": 25,
              "marksObtained": 22,
              "weightage": 20
            },
            "MARK002": {
              "subjectName": "Mathematics",
              "subjectCode": "MATH101",
              "examComponent": "IA2",
              "maxMarks": 25,
              "marksObtained": 23,
              "weightage": 20
            },
            "MARK003": {
              "subjectName": "Mathematics",
              "subjectCode": "MATH101",
              "examComponent": "Assignment",
              "maxMarks": 10,
              "marksObtained": 9,
              "weightage": 10
            },
            "MARK004": {
              "subjectName": "Physics",
              "subjectCode": "PHY101",
              "examComponent": "IA1",
              "maxMarks": 25,
              "marksObtained": 20,
              "weightage": 20
            },
            "MARK005": {
              "subjectName": "Physics",
              "subjectCode": "PHY101",
              "examComponent": "Practical",
              "maxMarks": 50,
              "marksObtained": 45,
              "weightage": 30
            }
          }
        }
      }
    }
  }
}
```

### 2. Results Data Structure

```
schools/
  {schoolId}/
    students/
      {studentUUID}/
        results/
          {resultId}: {
            "examName": "1st Semester Final Exam",
            "semesterCode": "SEM1",  // Optional
            "academicYear": "2023-24",  // Optional
            "sgpa": 8.5,  // Optional
            "cgpa": 8.3,  // Optional
            "totalCreditsEarned": 24,  // Optional
            "isPublished": true,
            "subjects": [
              {
                "subjectName": "Mathematics",
                "subjectCode": "MATH101",  // Optional
                "grade": "A+",
                "gradePoints": 9.0,  // Optional
                "credits": 4,  // Optional
                "resultStatus": "Pass"  // Pass, Fail, Absent
              }
            ]
          }
```

**Example Data:**
```json
{
  "schools": {
    "SCHOOL001": {
      "students": {
        "STU-2024-001": {
          "results": {
            "RESULT001": {
              "examName": "1st Semester Final Exam",
              "semesterCode": "SEM1",
              "academicYear": "2023-24",
              "sgpa": 8.5,
              "cgpa": 8.5,
              "totalCreditsEarned": 24,
              "isPublished": true,
              "subjects": [
                {
                  "subjectName": "Mathematics",
                  "subjectCode": "MATH101",
                  "grade": "A+",
                  "gradePoints": 9.0,
                  "credits": 4,
                  "resultStatus": "Pass"
                },
                {
                  "subjectName": "Physics",
                  "subjectCode": "PHY101",
                  "grade": "A",
                  "gradePoints": 8.5,
                  "credits": 4,
                  "resultStatus": "Pass"
                },
                {
                  "subjectName": "Chemistry",
                  "subjectCode": "CHEM101",
                  "grade": "B+",
                  "gradePoints": 7.5,
                  "credits": 4,
                  "resultStatus": "Pass"
                }
              ]
            },
            "RESULT002": {
              "examName": "2nd Semester Final Exam",
              "semesterCode": "SEM2",
              "academicYear": "2023-24",
              "sgpa": 8.2,
              "cgpa": 8.35,
              "totalCreditsEarned": 48,
              "isPublished": true,
              "subjects": [
                {
                  "subjectName": "Advanced Mathematics",
                  "subjectCode": "MATH201",
                  "grade": "A",
                  "gradePoints": 8.5,
                  "credits": 4,
                  "resultStatus": "Pass"
                },
                {
                  "subjectName": "Electronics",
                  "subjectCode": "ELEC201",
                  "grade": "A-",
                  "gradePoints": 8.0,
                  "credits": 4,
                  "resultStatus": "Pass"
                }
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

### Step 1: Enable Modules via Firebase

Both modules are controlled by **remote feature flags** in Firebase Realtime Database:

```
featureFlags/
  modules/
    SCHOOL001/
      internalMark: true
      result: true
```

**Enable via Firebase Console:**
1. Go to Firebase Realtime Database
2. Navigate to `featureFlags/modules/{schoolId}/`
3. Set:
   - `internalMark: true` (enable Internal Marks)
   - `result: true` (enable Results)

**OR enable globally for all schools:**
```
featureFlags/
  modules/
    global/
      internalMark: true
      result: true
```

### Step 2: Add Sample Data (for Testing)

Use the Firebase Console or the provided setup script:

#### Option A: Manual Entry (Firebase Console)
1. Go to Firebase Realtime Database
2. Navigate to `schools/{schoolId}/students/{studentUUID}/`
3. Add `internalMarks` and `results` nodes with sample data (see structure above)

#### Option B: Using Node.js Script

Create a file `setup_internal_results_data.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./rtccsattendancesystem-firebase-adminsdk-fbsvc-af29a472c4.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://rtccsattendancesystem-default-rtdb.firebaseio.com'
});

const db = admin.database();

async function setupInternalMarksAndResults() {
  const schoolId = 'SCHOOL001';
  const studentUUID = 'STU-2024-001';

  // Internal Marks Data
  const internalMarksRef = db.ref(`schools/${schoolId}/students/${studentUUID}/internalMarks`);
  await internalMarksRef.set({
    MARK001: {
      subjectName: 'Mathematics',
      subjectCode: 'MATH101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 22,
      weightage: 20
    },
    MARK002: {
      subjectName: 'Mathematics',
      subjectCode: 'MATH101',
      examComponent: 'IA2',
      maxMarks: 25,
      marksObtained: 23,
      weightage: 20
    },
    MARK003: {
      subjectName: 'Physics',
      subjectCode: 'PHY101',
      examComponent: 'IA1',
      maxMarks: 25,
      marksObtained: 20,
      weightage: 20
    },
    MARK004: {
      subjectName: 'Physics',
      subjectCode: 'PHY101',
      examComponent: 'Practical',
      maxMarks: 50,
      marksObtained: 45,
      weightage: 30
    }
  });

  // Results Data
  const resultsRef = db.ref(`schools/${schoolId}/students/${studentUUID}/results`);
  await resultsRef.set({
    RESULT001: {
      examName: '1st Semester Final Exam',
      semesterCode: 'SEM1',
      academicYear: '2023-24',
      sgpa: 8.5,
      cgpa: 8.5,
      totalCreditsEarned: 24,
      isPublished: true,
      subjects: [
        {
          subjectName: 'Mathematics',
          subjectCode: 'MATH101',
          grade: 'A+',
          gradePoints: 9.0,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Physics',
          subjectCode: 'PHY101',
          grade: 'A',
          gradePoints: 8.5,
          credits: 4,
          resultStatus: 'Pass'
        },
        {
          subjectName: 'Chemistry',
          subjectCode: 'CHEM101',
          grade: 'B+',
          gradePoints: 7.5,
          credits: 4,
          resultStatus: 'Pass'
        }
      ]
    }
  });

  console.log('✅ Internal Marks and Results data added successfully!');
  process.exit(0);
}

setupInternalMarksAndResults().catch(error => {
  console.error('❌ Error:', error);
  process.exit(1);
});
```

Run the script:
```bash
node setup_internal_results_data.js
```

### Step 3: Security Rules

Add these security rules to Firebase:

```json
{
  "rules": {
    "schools": {
      "$schoolId": {
        "students": {
          "$studentUUID": {
            "internalMarks": {
              ".read": "auth != null && (
                data.parent().child('uuid').val() === auth.uid ||
                root.child('schools').child($schoolId).child('admins').child(auth.uid).exists()
              )",
              ".write": "auth != null && root.child('schools').child($schoolId).child('admins').child(auth.uid).exists()"
            },
            "results": {
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

---

## Testing

### Test Internal Marks Module
1. Enable the module: `featureFlags/modules/{schoolId}/internalMark: true`
2. Add sample internal marks data (see above)
3. Login to student app
4. Navigate to **More** → **Internal Marks**
5. Verify:
   - ✅ Marks load successfully
   - ✅ Can toggle between "Group by Subject" and "Group by Component"
   - ✅ Overall summary shows correct percentage
   - ✅ Pull-to-refresh works
   - ✅ Works offline (cached data)
   - ✅ Module guard blocks if disabled

### Test Results Module
1. Enable the module: `featureFlags/modules/{schoolId}/result: true`
2. Add sample results data (see above)
3. Login to student app
4. Navigate to **More** → **Results**
5. Verify:
   - ✅ Results load successfully
   - ✅ CGPA summary displays at top
   - ✅ Can expand/collapse semester cards
   - ✅ Subject-wise results show grades, GP, credits
   - ✅ Pass/Fail status displays correctly
   - ✅ Unpublished results show "Not Published" message
   - ✅ Pull-to-refresh works
   - ✅ Works offline (cached data)
   - ✅ Module guard blocks if disabled

### Test Error Scenarios
1. **No internet + no cache**: Should show error with retry button
2. **Timeout**: Should gracefully fallback to cached data
3. **Module disabled**: Should show "Module not available" screen
4. **Empty data**: Should show "No marks/results available" message

---

## Architecture

### Providers
- **InternalMarksProvider**: Manages internal marks data, caching, grouping
- **ResultsProvider**: Manages semester results, SGPA/CGPA calculations

### Screens
- **InternalMarksScreen**: UI for viewing internal assessment marks
- **ResultsScreen**: UI for viewing semester exam results

### Services (Shared)
- **ModuleAvailabilityService**: Feature flag checking and module guard
- **ModuleErrorHandler**: Consistent error/loading/empty states

### Caching
- Uses **SharedPreferences** for offline support
- Cache key format:
  - Internal Marks: `internal_marks_{schoolId}_{studentUUID}`
  - Results: `results_{schoolId}_{studentUUID}`
- Cache timestamp tracked for freshness

---

## Key Features

### Offline Support
Both modules cache data locally and work offline:
- First load fetches from Firebase
- Subsequent loads show cached data immediately
- Pull-to-refresh fetches fresh data
- Orange banner indicates offline/cached mode

### Error Handling
- Network timeout: 15 seconds
- Graceful fallback to cached data
- Retry mechanism on errors
- User-friendly error messages

### Module Guards
- Checks feature flags before loading
- Shows "Module not available" if disabled
- Redirects to dashboard with message
- No crashes or broken UI

### Performance
- Lazy loading: Only loads when accessed
- Efficient grouping algorithms
- Minimal re-renders with Provider
- Cached data prevents redundant fetches

---

## Troubleshooting

### Internal Marks Not Loading
1. Check feature flag: `featureFlags/modules/{schoolId}/internalMark` is `true`
2. Verify data exists at: `schools/{schoolId}/students/{studentUUID}/internalMarks`
3. Check Firebase security rules allow read access
4. Look for errors in Flutter logs

### Results Not Loading
1. Check feature flag: `featureFlags/modules/{schoolId}/result` is `true`
2. Verify data exists at: `schools/{schoolId}/students/{studentUUID}/results`
3. Ensure `isPublished: true` for results to show
4. Check Firebase security rules allow read access

### Module Access Denied
1. Verify student is logged in
2. Check student's `schoolId` matches feature flag path
3. Ensure Firebase Auth token is valid
4. Check security rules allow student to read their own data

### Offline Data Not Working
1. Verify student loaded data at least once while online
2. Check SharedPreferences is working (device storage permissions)
3. Clear app cache and retry: Settings → Apps → RTCCS Student → Clear Cache

---

## Admin Notes

### Data Entry Recommendations
- Use consistent `examComponent` values: "IA1", "IA2", "Assignment", "Practical"
- Always include `maxMarks` and `marksObtained`
- Optional fields like `weightage`, `credits`, `gradePoints` enhance UI display
- Set `isPublished: false` until results are finalized

### Grading System
The app color-codes performance:
- **SGPA/Percentage >= 75%**: Green (Excellent)
- **SGPA/Percentage 60-74%**: Blue (Good)
- **SGPA/Percentage 50-59%**: Orange (Average)
- **SGPA/Percentage 40-49%**: Dark Orange (Below Average)
- **SGPA/Percentage < 40%**: Red (Poor)

### Supported Grade Values
- A+, A, A-, B+, B, B-, C+, C, C-, D, E, F
- O (Outstanding), P (Pass), F (Fail)
- Color-coded based on grade tier

---

## Files Modified/Created

### New Files
1. `lib/providers/optional/internal_marks_provider.dart` ✅
2. `lib/screens/optional/internal_marks_screen.dart` ✅
3. `lib/screens/optional/results_screen.dart` ✅
4. `INTERNAL_RESULTS_SETUP.md` (this file) ✅

### Modified Files
1. `lib/main.dart` - Added providers, imports, routes ✅
2. `lib/providers/optional/results_provider.dart` - Enhanced with SGPA/CGPA ✅

### Existing Files (Unchanged)
- Core attendance logic (BLE, QR)
- Dashboard screen
- Feature flags config
- Module availability service
- Error handler service

---

## Summary

✅ **Internal Marks Module**: Complete with subject/component grouping, caching, offline support  
✅ **Results Module**: Complete with SGPA/CGPA, semester expansion, pass/fail indicators  
✅ **Feature Flags**: Remote control via Firebase  
✅ **Module Guards**: Access control implemented  
✅ **Error Handling**: Retry mechanisms and fallbacks  
✅ **Offline Support**: SharedPreferences caching  
✅ **Independent**: No impact on attendance or core features  

Both modules are production-ready and safe to deploy! 🚀
