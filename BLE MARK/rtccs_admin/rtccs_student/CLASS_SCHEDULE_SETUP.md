# Class Schedule (Timetable) - Firebase Data Structure

## Database Path
```
timetable/
  {schoolId}/
    {classId}/
      monday/
        - 0:
            startTime: "09:00"
            endTime: "10:00"
            subject: "Mathematics"
            subjectCode: "MATH101"
            teacher: "Dr. Sharma"
            facultyName: "Dr. Sharma"  // Alternative field name
            room: "Room 101"
            classRoom: "Room 101"  // Alternative field name
        - 1:
            startTime: "10:15"
            endTime: "11:15"
            subject: "Physics"
            subjectCode: "PHY101"
            teacher: "Prof. Kumar"
            room: "Lab B"
      tuesday/
        - 0:
            startTime: "09:00"
            endTime: "10:00"
            subject: "Chemistry"
            subjectCode: "CHEM101"
            teacher: "Dr. Verma"
            room: "Room 202"
      ...
```

## Sample Data (JSON Format)

```json
{
  "timetable": {
    "school_001": {
      "class_10a": {
        "monday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Mathematics",
            "subjectCode": "MATH101",
            "teacher": "Dr. Rajesh Sharma",
            "room": "Room 101",
            "date": "2025-11-28"
          },
          {
            "startTime": "10:15",
            "endTime": "11:15",
            "subject": "Physics",
            "subjectCode": "PHY101",
            "teacher": "Prof. Amit Kumar",
            "room": "Lab B"
          },
          {
            "startTime": "11:30",
            "endTime": "12:30",
            "subject": "English",
            "subjectCode": "ENG101",
            "teacher": "Mrs. Priya Gupta",
            "room": "Room 105"
          },
          {
            "startTime": "13:30",
            "endTime": "14:30",
            "subject": "Chemistry",
            "subjectCode": "CHEM101",
            "teacher": "Dr. Suresh Verma",
            "room": "Lab A"
          }
        ],
        "tuesday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Chemistry",
            "subjectCode": "CHEM101",
            "teacher": "Dr. Suresh Verma",
            "room": "Room 202"
          },
          {
            "startTime": "10:15",
            "endTime": "11:15",
            "subject": "Mathematics",
            "subjectCode": "MATH101",
            "teacher": "Dr. Rajesh Sharma",
            "room": "Room 101"
          },
          {
            "startTime": "11:30",
            "endTime": "12:30",
            "subject": "Computer Science",
            "subjectCode": "CS101",
            "teacher": "Mr. Ravi Singh",
            "room": "Computer Lab"
          }
        ],
        "wednesday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Biology",
            "subjectCode": "BIO101",
            "teacher": "Dr. Anjali Mehta",
            "room": "Bio Lab"
          },
          {
            "startTime": "10:15",
            "endTime": "11:15",
            "subject": "English",
            "subjectCode": "ENG101",
            "teacher": "Mrs. Priya Gupta",
            "room": "Room 105"
          }
        ],
        "thursday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Physics",
            "subjectCode": "PHY101",
            "teacher": "Prof. Amit Kumar",
            "room": "Lab B"
          },
          {
            "startTime": "10:15",
            "endTime": "11:15",
            "subject": "Physical Education",
            "subjectCode": "PE101",
            "teacher": "Coach Ramesh",
            "room": "Sports Ground"
          }
        ],
        "friday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Mathematics",
            "subjectCode": "MATH101",
            "teacher": "Dr. Rajesh Sharma",
            "room": "Room 101"
          },
          {
            "startTime": "10:15",
            "endTime": "11:15",
            "subject": "Hindi",
            "subjectCode": "HIN101",
            "teacher": "Mrs. Kavita Joshi",
            "room": "Room 103"
          }
        ],
        "saturday": [
          {
            "startTime": "09:00",
            "endTime": "10:00",
            "subject": "Social Studies",
            "subjectCode": "SS101",
            "teacher": "Mr. Prakash Rao",
            "room": "Room 201"
          }
        ],
        "sunday": []
      }
    }
  }
}
```

## Feature Flag Configuration

Enable the Class Schedule module in Firebase:

```json
{
  "app_config": {
    "student_features": {
      "global": {
        "classSchedule": true,
        "hostelAttendance": false,
        "itle": false,
        "feesPaid": false,
        "certificates": false,
        "hallTicket": false,
        "examTimeTable": false,
        "registerSubject": false,
        "internalMark": false,
        "result": false,
        "calendar": false,
        "feedback": false
      },
      "school_001": {
        "classSchedule": true,
        "feesPaid": true
      }
    }
  }
}
```

## Data Fields Reference

### Required Fields
- **day** (string): Day of week (monday, tuesday, etc.) - lowercase
- **startTime** (string): Start time in HH:MM format (24-hour)
- **endTime** (string): End time in HH:MM format (24-hour)
- **subject** (string): Subject name
- **teacher** (string): Teacher/faculty name
- **room** (string): Room/lab identifier

### Optional Fields
- **subjectCode** (string): Subject code (e.g., "MATH101")
- **date** (string): Specific date in YYYY-MM-DD format
- **facultyName** (string): Alternative field for teacher name
- **classRoom** (string): Alternative field for room
- **labRoom** (string): Alternative field for lab

### Alternative Data Structure (Object Format)

You can also use object format instead of array:

```json
{
  "monday": {
    "period_1": {
      "startTime": "09:00",
      "endTime": "10:00",
      "subject": "Mathematics",
      "teacher": "Dr. Sharma",
      "room": "Room 101"
    },
    "period_2": {
      "startTime": "10:15",
      "endTime": "11:15",
      "subject": "Physics",
      "teacher": "Prof. Kumar",
      "room": "Lab B"
    }
  }
}
```

## Security Rules

Ensure students can only read their own class timetable:

```json
{
  "rules": {
    "timetable": {
      "$schoolId": {
        "$classId": {
          ".read": "auth != null && 
                   root.child('students').child(auth.uid).child('schoolId').val() == $schoolId &&
                   root.child('students').child(auth.uid).child('classId').val() == $classId",
          ".write": false
        }
      }
    }
  }
}
```

## How It Works

1. **Student logs in** → App fetches student's `schoolId` and `classId`

2. **Feature flag check** → App checks if `classSchedule` is enabled for the school

3. **Data fetch** → App loads timetable from:
   ```
   timetable/{schoolId}/{classId}
   ```

4. **Caching** → Data is cached locally using SharedPreferences

5. **Offline mode** → If no internet, app shows cached timetable

6. **Refresh** → Pull-to-refresh updates from Firebase and updates cache

## Important Notes

- ✅ Times are sorted automatically by the app (ascending order)
- ✅ Day names must be lowercase (monday, tuesday, etc.)
- ✅ Time format: HH:MM (24-hour, e.g., "09:00", "14:30")
- ✅ Empty days (no classes) should have empty array: `"sunday": []`
- ✅ Overlapping slots won't crash the app (shown as-is)
- ✅ Data is read-only for students
- ✅ Students cannot edit or modify timetable
- ✅ Students cannot access other class timetables

## Testing Steps

1. Add sample data to Firebase at `timetable/school_001/class_10a/`
2. Enable feature flag: `app_config/student_features/global/classSchedule: true`
3. Ensure student profile has matching `schoolId` and `classId`
4. Open app → Dashboard → Tap "Class Schedule"
5. Verify Today's Schedule shows current day's classes
6. Verify Week tabs show respective day's classes
7. Test pull-to-refresh
8. Test offline mode (disable internet, reopen app)

## Troubleshooting

**Issue**: "No Schedule Available"
- Check if timetable exists at correct path
- Verify student has schoolId and classId in profile
- Check Firebase security rules

**Issue**: "No internet connection and no timetable data cached yet"
- Enable internet for first load
- After first load, offline mode will work

**Issue**: Module not showing on dashboard
- Check feature flag: `app_config/student_features/global/classSchedule`
- Should be `true`

**Issue**: "Feature Unavailable" message
- Feature flag is disabled
- Enable in Firebase: `classSchedule: true`
