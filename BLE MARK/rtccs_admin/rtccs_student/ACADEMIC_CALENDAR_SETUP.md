# Academic Calendar Module Setup Guide

## Overview
The Academic Calendar module allows students to view college events, holidays, exams, and important academic dates in a monthly calendar view with filtering capabilities.

## Features
- ✅ Monthly calendar view with event highlighting
- ✅ Event type filtering (All, Holidays, Exams, College Events)
- ✅ Event details on date selection
- ✅ Color-coded event types
- ✅ Offline support with caching
- ✅ Feature flag control (`isCalendarEnabled`)
- ✅ Pull-to-refresh
- ✅ Month/year navigation

---

## Firebase Database Structure

### Path: `schools/{schoolId}/academicCalendar/{eventId}`

```json
{
  "schools": {
    "{schoolId}": {
      "academicCalendar": {
        "event_001": {
          "date": "2025-12-25",
          "title": "Christmas Holiday",
          "description": "College will remain closed for Christmas celebration",
          "eventType": "Holiday",
          "isHoliday": true
        },
        "event_002": {
          "date": "2025-12-15",
          "title": "Mid Term Examination - Computer Science",
          "description": "Mid term exam for semester 5 - Computer Science Engineering",
          "eventType": "Exam",
          "isHoliday": false
        },
        "event_003": {
          "date": "2025-12-20",
          "title": "Annual Day Celebration",
          "description": "College annual day - cultural events and prize distribution",
          "eventType": "College Event",
          "isHoliday": false
        },
        "event_004": {
          "date": "2026-01-01",
          "title": "New Year Holiday",
          "description": "College closed for New Year",
          "eventType": "Holiday",
          "isHoliday": true
        },
        "event_005": {
          "date": "2026-01-15",
          "title": "Guest Lecture - AI & ML",
          "description": "Special guest lecture by industry expert on Artificial Intelligence",
          "eventType": "Lecture",
          "isHoliday": false
        }
      }
    }
  }
}
```

### Event Model Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `date` | String | ✅ Yes | Event date in YYYY-MM-DD format | `"2025-12-25"` |
| `title` | String | ✅ Yes | Event name/title | `"Christmas Holiday"` |
| `description` | String | ❌ No | Detailed description | `"College will remain closed"` |
| `eventType` | String | ✅ Yes | Event category | `"Holiday"`, `"Exam"`, `"College Event"`, `"Lecture"`, `"Other"` |
| `isHoliday` | Boolean | ✅ Yes | Whether this is a holiday | `true` or `false` |

### Event Types
- **Holiday**: College closed days (red color)
- **Exam**: Examination days (orange color)
- **College Event**: Special events, celebrations (teal color)
- **Lecture**: Guest lectures, workshops (light teal color)
- **Other**: Miscellaneous events (gray color)

---

## Feature Flag Configuration

### Path: `schools/{schoolId}/featureFlags/modules/calendar`

```json
{
  "schools": {
    "{schoolId}": {
      "featureFlags": {
        "modules": {
          "calendar": true
        }
      }
    }
  }
}
```

### Behavior
- **`true`**: Calendar module is enabled and accessible
- **`false`**: Calendar tile is hidden; direct access shows "Academic calendar is currently not available."

---

## Firebase Security Rules

Add these rules to your `firebase-database.rules.json`:

```json
{
  "rules": {
    "schools": {
      "$schoolId": {
        "academicCalendar": {
          ".read": "auth != null && root.child('students').child(auth.uid).child('schoolId').val() == $schoolId",
          ".write": "auth != null && root.child('schools').child($schoolId).child('admins').child(auth.uid).exists()",
          "$eventId": {
            ".validate": "newData.hasChildren(['date', 'title', 'eventType', 'isHoliday'])"
          }
        }
      }
    }
  }
}
```

### Security Explanation
- **Read**: Any authenticated student of the school can read calendar events
- **Write**: Only school admins can add/modify calendar events
- **Validation**: Required fields must be present

---

## How to Use

### For Students

1. **Access Calendar**:
   - Tap **More** → **Academic Calendar**
   - Or navigate directly via `/calendar` route

2. **View Calendar**:
   - Monthly view with highlighted event dates
   - Red dots: Holidays
   - Orange dots: Exams
   - Blue dots: Other events

3. **Select a Date**:
   - Tap any date with events
   - View all events for that specific date below the calendar

4. **Filter Events**:
   - Tap filter icon (top-right)
   - Choose: **All Events**, **Holidays**, **Exams**, or **College Events**
   - Calendar and event list update automatically

5. **Navigate Months**:
   - Use left/right arrows to change months
   - Tap format button to switch between month/2-week view

6. **Refresh Data**:
   - Pull down to refresh
   - Updates from Firebase and clears cache

### For Admins (Adding Events)

Use the provided setup script or add events manually in Firebase Console.

---

## Setup Script

A Node.js script `setup_academic_calendar_data.js` is provided for quick setup with sample data.

### Prerequisites
```bash
npm install firebase-admin
```

### Run Script
```bash
node setup_academic_calendar_data.js
```

### What It Does
1. ✅ Creates 15+ sample calendar events
2. ✅ Includes holidays, exams, college events, and lectures
3. ✅ Covers December 2025 - February 2026
4. ✅ Enables feature flag (`calendar: true`)
5. ✅ Sets realistic dates and descriptions

---

## Testing Checklist

### 1. Feature Flag Testing
- [ ] With flag `true`: Calendar accessible, shows events
- [ ] With flag `false`: Calendar tile hidden, direct access shows unavailable message
- [ ] Toggle flag and verify immediate effect after app restart

### 2. Calendar Display
- [ ] Calendar shows current month on open
- [ ] Dates with events show colored dots
- [ ] Holidays show red dots
- [ ] Exams show orange dots
- [ ] Today's date is highlighted (blue circle)
- [ ] Selected date is highlighted (green circle)

### 3. Event Selection
- [ ] Tap date with events → shows event list below calendar
- [ ] Tap date without events → no event list shown
- [ ] Multiple events on same date → all displayed
- [ ] Event cards show correct icon, color, title, date, type badge

### 4. Filtering
- [ ] Filter by "All Events" → shows all events
- [ ] Filter by "Holidays" → shows only holidays
- [ ] Filter by "Exams" → shows only exams
- [ ] Filter by "College Events" → shows only college events
- [ ] Filter indicator shows active filter and count
- [ ] Clear filter by tapping 'X' → returns to all events

### 5. Navigation
- [ ] Left/right arrows navigate months
- [ ] Format button toggles month/2-week view
- [ ] Event tap in list scrolls calendar to that date
- [ ] Calendar remembers selected date when navigating months

### 6. Offline Mode
- [ ] Load calendar with internet → caches data
- [ ] Disable internet → shows cached data with orange indicator
- [ ] Offline message: "Showing last updated calendar."
- [ ] No cache + no internet → shows error message
- [ ] Pull-to-refresh offline → shows error, keeps cached data

### 7. Error Handling
- [ ] No events in database → shows "No calendar events available"
- [ ] Network timeout → shows cached data with timeout message
- [ ] Invalid date format → event ignored, no crash
- [ ] Missing required fields → event ignored, no crash

### 8. Data Validation
- [ ] Events sorted by date (earliest first)
- [ ] Event cards show correct color based on type
- [ ] Holiday events show celebration icon
- [ ] Exam events show assignment icon
- [ ] College event shows event icon
- [ ] Lecture shows school icon
- [ ] Description text truncates after 2 lines in list view

### 9. Performance
- [ ] Calendar loads within 2 seconds (with network)
- [ ] Month navigation is smooth (no lag)
- [ ] Filter changes are instant
- [ ] Pull-to-refresh completes within 3 seconds
- [ ] No memory leaks (test with 100+ events)

### 10. UI/UX
- [ ] All text is readable (good contrast)
- [ ] Icons match event types
- [ ] Color coding is consistent
- [ ] Calendar fits screen without horizontal scroll
- [ ] Event cards are tappable with visual feedback
- [ ] Loading spinner shows during data fetch

---

## Sample Event Data

### Holidays
```json
{
  "date": "2025-12-25",
  "title": "Christmas Holiday",
  "description": "College will remain closed for Christmas celebration",
  "eventType": "Holiday",
  "isHoliday": true
}
```

### Exams
```json
{
  "date": "2025-12-15",
  "title": "Mid Term Examination - Computer Science",
  "description": "Mid term exam for semester 5 - Computer Science Engineering",
  "eventType": "Exam",
  "isHoliday": false
}
```

### College Events
```json
{
  "date": "2025-12-20",
  "title": "Annual Day Celebration",
  "description": "College annual day - cultural events and prize distribution",
  "eventType": "College Event",
  "isHoliday": false
}
```

### Lectures
```json
{
  "date": "2026-01-15",
  "title": "Guest Lecture - AI & ML",
  "description": "Special guest lecture by industry expert on Artificial Intelligence",
  "eventType": "Lecture",
  "isHoliday": false
}
```

---

## Troubleshooting

### Calendar Not Showing
- ✅ Check feature flag: `schools/{schoolId}/featureFlags/modules/calendar` = `true`
- ✅ Verify student has valid `schoolId`
- ✅ Check Firebase security rules allow student read access
- ✅ Ensure at least one event exists in database

### Events Not Appearing
- ✅ Verify date format is YYYY-MM-DD
- ✅ Check all required fields present (date, title, eventType, isHoliday)
- ✅ Ensure eventType is valid (Holiday/Exam/College Event/Lecture/Other)
- ✅ Clear app cache and pull-to-refresh

### Filter Not Working
- ✅ Verify eventType field matches filter criteria exactly
- ✅ Case-sensitive: "Exam" not "exam"
- ✅ Check provider state updates (notifyListeners called)

### Calendar Date Selection Not Working
- ✅ Ensure TableCalendar package is installed (`table_calendar: ^3.0.9`)
- ✅ Check selectedDayPredicate is set correctly
- ✅ Verify onDaySelected callback updates provider state

### Offline Mode Not Working
- ✅ Verify SharedPreferences has cached data
- ✅ Check cache key format: `academic_calendar_{schoolId}_{studentUUID}`
- ✅ Ensure loadCachedEvents called before Firebase fetch

---

## Implementation Notes

### Provider Architecture
- **AcademicCalendarProvider**: Manages calendar state, Firebase fetch, caching
- **Models**: CalendarEvent with date, title, description, eventType, isHoliday
- **Caching**: SharedPreferences stores JSON-encoded event list
- **Timeout**: 15-second Firebase fetch timeout

### Screen Components
- **TableCalendar**: Third-party calendar widget
- **Event Cards**: Color-coded by type with icons
- **Filter Menu**: PopupMenuButton with radio buttons
- **Selected Date View**: Shows events for tapped date
- **All Events List**: Grouped by month with headers

### State Management
- Selected date state
- Filter state (all/holidays/exams/events)
- Loading state
- Error state
- Cache state (isFromCache flag)

### Color Scheme
- **Holiday**: Red (#FF6B6B)
- **Exam**: Orange (#FFB84D)
- **College Event**: Teal (#4ECDC4)
- **Lecture**: Light Teal (#95E1D3)
- **Other**: Gray (#9B9B9B)

---

## Admin Quick Reference

### Add Single Event
```javascript
// Firebase Console or Admin SDK
firebase.database().ref('schools/SCHOOL001/academicCalendar/event_new').set({
  date: '2026-02-14',
  title: 'Sports Day',
  description: 'Annual inter-college sports competition',
  eventType: 'College Event',
  isHoliday: false
});
```

### Bulk Add Events
Use the provided `setup_academic_calendar_data.js` script.

### Enable/Disable Module
```javascript
firebase.database().ref('schools/SCHOOL001/featureFlags/modules/calendar').set(true);  // Enable
firebase.database().ref('schools/SCHOOL001/featureFlags/modules/calendar').set(false); // Disable
```

### Delete Event
```javascript
firebase.database().ref('schools/SCHOOL001/academicCalendar/event_001').remove();
```

---

## API Reference

### AcademicCalendarProvider

#### Methods
- `fetchCalendarEvents({schoolId, studentUUID, program, year})`: Fetch events from Firebase
- `loadCachedEvents(schoolId, studentUUID)`: Load from local cache
- `getEventsForDate(DateTime date)`: Get events for specific date
- `getEventsForMonth(DateTime month)`: Get events for specific month
- `setSelectedDate(DateTime date)`: Update selected date
- `setFilter(String filter)`: Update filter (all/holidays/exams/events)
- `clearCache(schoolId, studentUUID)`: Clear cached data
- `clear()`: Reset all state

#### Getters
- `events`: All events
- `filteredEvents`: Events matching current filter
- `holidays`: All holiday events
- `exams`: All exam events
- `collegeEvents`: All college event entries
- `isLoading`: Loading state
- `error`: Error message (if any)
- `isFromCache`: Whether data is from cache
- `selectedDate`: Currently selected date
- `selectedFilter`: Active filter

#### Helper Methods
- `hasEventsOnDate(DateTime date)`: Check if date has events
- `isHoliday(DateTime date)`: Check if date is a holiday

### CalendarEvent Model

#### Properties
- `id`: Event unique ID
- `date`: Event date (DateTime)
- `title`: Event title
- `description`: Event description (optional)
- `eventType`: Event category (Holiday/Exam/College Event/Lecture/Other)
- `isHoliday`: Holiday flag

#### Getters
- `isExam`: Whether event is exam
- `isEvent`: Whether event is college event
- `isLecture`: Whether event is lecture
- `typeColor`: Color based on event type
- `typeIcon`: Icon based on event type

---

## Dependencies

### Required Packages
```yaml
dependencies:
  table_calendar: ^3.0.9  # Calendar widget
  intl: ^0.18.1          # Date formatting
  provider: ^6.0.0       # State management
  firebase_database: ^10.0.0  # Firebase integration
  shared_preferences: ^2.2.2  # Caching
  google_fonts: ^6.1.0   # Typography
```

### Installation
```bash
flutter pub add table_calendar
flutter pub get
```

---

## Version History

### v1.0.0 (November 2025)
- ✅ Initial release
- ✅ Monthly calendar view
- ✅ Event type filtering
- ✅ Offline caching
- ✅ Feature flag support
- ✅ Color-coded event types
- ✅ Pull-to-refresh

---

## Support

For issues or questions:
1. Check this documentation
2. Review Firebase Console for data correctness
3. Check feature flag status
4. Verify security rules
5. Test with sample data script

---

## Related Modules

- **Exam Timetable**: Detailed exam schedule with room/seat info
- **Internal Marks**: Continuous assessment marks
- **Results**: Semester exam results with SGPA/CGPA

---

**Module Status**: ✅ Production Ready  
**Last Updated**: November 29, 2025  
**Dependencies Check**: ✅ All packages compatible
