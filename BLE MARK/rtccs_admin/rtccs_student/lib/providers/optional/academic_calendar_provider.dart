import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Model for a calendar event
class CalendarEvent {
  final String id;
  final DateTime date;
  final String title;
  final String? description;
  final String eventType; // Holiday, Exam, Lecture, College Event, Other
  final bool isHoliday;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.description,
    required this.eventType,
    required this.isHoliday,
  });

  factory CalendarEvent.fromMap(String id, Map<dynamic, dynamic> map) {
    return CalendarEvent(
      id: id,
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toString()),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      eventType: map['eventType']?.toString() ?? 'Other',
      isHoliday: map['isHoliday'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'title': title,
      'description': description,
      'eventType': eventType,
      'isHoliday': isHoliday,
    };
  }

  bool get isExam => eventType.toLowerCase() == 'exam';
  bool get isEvent => eventType.toLowerCase() == 'college event';
  bool get isLecture => eventType.toLowerCase() == 'lecture';

  Color get typeColor {
    if (isHoliday) return const Color(0xFFFF6B6B); // Red for holidays
    if (isExam) return const Color(0xFFFFB84D); // Orange for exams
    if (isEvent) return const Color(0xFF4ECDC4); // Teal for events
    if (isLecture) return const Color(0xFF95E1D3); // Light teal for lectures
    return const Color(0xFF9B9B9B); // Gray for other
  }

  IconData get typeIcon {
    if (isHoliday) return Icons.celebration;
    if (isExam) return Icons.assignment;
    if (isEvent) return Icons.event;
    if (isLecture) return Icons.school;
    return Icons.info;
  }
}

class AcademicCalendarProvider with ChangeNotifier {
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all'; // all, holidays, exams, events

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;
  DateTime get selectedDate => _selectedDate;
  String get selectedFilter => _selectedFilter;

  /// Get events for a specific date
  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
  }

  /// Get events for a specific month
  List<CalendarEvent> getEventsForMonth(DateTime month) {
    return _events.where((event) {
      return event.date.year == month.year && event.date.month == month.month;
    }).toList();
  }

  /// Get filtered events
  List<CalendarEvent> get filteredEvents {
    switch (_selectedFilter.toLowerCase()) {
      case 'holidays':
        return _events.where((e) => e.isHoliday).toList();
      case 'exams':
        return _events.where((e) => e.isExam).toList();
      case 'events':
        return _events.where((e) => e.isEvent).toList();
      default:
        return _events;
    }
  }

  /// Get holidays
  List<CalendarEvent> get holidays => _events.where((e) => e.isHoliday).toList();

  /// Get exams
  List<CalendarEvent> get exams => _events.where((e) => e.isExam).toList();

  /// Get college events
  List<CalendarEvent> get collegeEvents => _events.where((e) => e.isEvent).toList();

  /// Check if a date has events
  bool hasEventsOnDate(DateTime date) {
    return _events.any((event) =>
        event.date.year == date.year &&
        event.date.month == date.month &&
        event.date.day == date.day);
  }

  /// Check if a date is a holiday
  bool isHoliday(DateTime date) {
    return _events.any((event) =>
        event.isHoliday &&
        event.date.year == date.year &&
        event.date.month == date.month &&
        event.date.day == date.day);
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Load cached calendar events
  Future<void> loadCachedEvents(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'academic_calendar_${schoolId}_$studentUUID';
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        _events = decoded.map((e) => CalendarEvent.fromMap(e['id'], e)).toList();
        _sortEvents();
        _isFromCache = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached calendar: $e');
    }
  }

  /// Fetch calendar events from Firebase
  Future<void> fetchCalendarEvents({
    required String schoolId,
    required String studentUUID,
    String? program,
    String? year,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Load from cache first
      await loadCachedEvents(schoolId, studentUUID);

      final db = FirebaseDatabase.instance;
      final ref = db.ref('schools/$schoolId/academicCalendar');

      // Set timeout
      final dataSnapshot = await ref.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (dataSnapshot.exists) {
        final Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
        final List<CalendarEvent> fetchedEvents = [];

        data.forEach((key, value) {
          if (value is Map) {
            try {
              fetchedEvents.add(CalendarEvent.fromMap(key.toString(), value));
            } catch (e) {
              debugPrint('Error parsing calendar event $key: $e');
            }
          }
        });

        _events = fetchedEvents;
        _sortEvents();
        _isFromCache = false;
        _error = null;

        // Cache the data
        await _cacheEvents(schoolId, studentUUID);
      } else {
        _events = [];
        _error = null;
      }
    } on TimeoutException catch (_) {
      _error = 'Request timed out. Showing cached data.';
      debugPrint('Calendar fetch timeout');
    } catch (e) {
      _error = 'Failed to load calendar: ${e.toString()}';
      debugPrint('Error fetching calendar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache calendar events
  Future<void> _cacheEvents(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'academic_calendar_${schoolId}_$studentUUID';
      final data = _events.map((e) => e.toMap()).toList();
      await prefs.setString(key, json.encode(data));

      // Save timestamp
      await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching calendar: $e');
    }
  }

  /// Sort events by date
  void _sortEvents() {
    _events.sort((a, b) => a.date.compareTo(b.date));
  }

  /// Clear cache
  Future<void> clearCache(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'academic_calendar_${schoolId}_$studentUUID';
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear current data
  void clear() {
    _events = [];
    _isLoading = false;
    _error = null;
    _isFromCache = false;
    _selectedDate = DateTime.now();
    _selectedFilter = 'all';
    notifyListeners();
  }
}
