import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for schedule/timetable entry
class ScheduleEntry {
  final String id;
  final String day; // monday, tuesday, etc.
  final String startTime; // e.g., "09:00"
  final String endTime; // e.g., "10:00"
  final String subject;
  final String subjectCode; // optional
  final String teacher;
  final String room;
  final String? date; // YYYY-MM-DD format (optional)

  ScheduleEntry({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.subjectCode = '',
    required this.teacher,
    required this.room,
    this.date,
  });

  factory ScheduleEntry.fromMap(Map<dynamic, dynamic> map, String id) {
    return ScheduleEntry(
      id: id,
      day: map['day']?.toString() ?? '',
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      subject: map['subject']?.toString() ?? map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      teacher: map['teacher']?.toString() ?? map['facultyName']?.toString() ?? '',
      room: map['room']?.toString() ?? map['classRoom']?.toString() ?? map['labRoom']?.toString() ?? '',
      date: map['date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'subjectCode': subjectCode,
      'teacher': teacher,
      'room': room,
      'date': date,
    };
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] ?? '',
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subject: json['subject'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      teacher: json['teacher'] ?? '',
      room: json['room'] ?? '',
      date: json['date'],
    );
  }

  String get timeSlot => '$startTime - $endTime';
}

/// Provider for class schedule/timetable
class ScheduleProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  List<ScheduleEntry> _schedule = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  bool _isFromCache = false;

  List<ScheduleEntry> get schedule => _schedule;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isFromCache => _isFromCache;

  static const String _cacheKey = 'timetable_cache';
  static const String _cacheTimestampKey = 'timetable_cache_timestamp';

  /// Load cached schedule
  Future<void> loadCachedSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _schedule = jsonList.map((json) => ScheduleEntry.fromJson(json)).toList();
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        _isFromCache = true;
        notifyListeners();
        print('[ScheduleProvider] Loaded from cache: ${_schedule.length} entries');
      }
    } catch (e) {
      print('[ScheduleProvider] Cache load error: $e');
    }
  }

  /// Save schedule to cache
  Future<void> _saveToCache(List<ScheduleEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('[ScheduleProvider] Saved to cache: ${entries.length} entries');
    } catch (e) {
      print('[ScheduleProvider] Cache save error: $e');
    }
  }

  /// Fetch class schedule from Firebase
  Future<void> fetchSchedule({
    required String schoolId,
    required String classId,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    // First load from cache if available
    if (_schedule.isEmpty) {
      await loadCachedSchedule();
    }

    try {
      final snapshot = await _db
          .ref('timetable/$schoolId/$classId')
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout: Unable to load schedule. Please check your network connection.');
            },
          );

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final entries = <ScheduleEntry>[];

        data.forEach((day, daySchedule) {
          if (daySchedule is List) {
            for (var i = 0; i < daySchedule.length; i++) {
              if (daySchedule[i] != null) {
                entries.add(ScheduleEntry.fromMap(
                  {...daySchedule[i], 'day': day},
                  '${day}_$i',
                ));
              }
            }
          } else if (daySchedule is Map) {
            // Support object format as well
            daySchedule.forEach((key, value) {
              if (value != null) {
                entries.add(ScheduleEntry.fromMap(
                  {...value, 'day': day},
                  '${day}_$key',
                ));
              }
            });
          }
        });

        // Sort entries by day and time
        entries.sort((a, b) {
          final dayCompare = _getDayOrder(a.day).compareTo(_getDayOrder(b.day));
          if (dayCompare != 0) return dayCompare;
          return a.startTime.compareTo(b.startTime);
        });

        _schedule = entries;
        _lastUpdated = DateTime.now();
        _isFromCache = false;
        _error = null;

        // Save to cache
        await _saveToCache(entries);
      } else {
        // No data on server
        if (_schedule.isEmpty) {
          _schedule = [];
          _error = null; // Not an error, just no data
        }
        // Keep cached data if server has no data
      }
    } catch (e) {
      // If we have cached data, keep showing it
      if (_schedule.isEmpty) {
        _error = e.toString();
      } else {
        // Show cached data but set error for "couldn't refresh" message
        _error = 'Showing last updated timetable. Couldn\'t refresh right now.';
      }
      print('[ScheduleProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _getDayOrder(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 0;
    }
  }

  /// Get today's schedule (sorted by time)
  List<ScheduleEntry> getTodaySchedule() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final todaySchedule = _schedule.where((entry) => entry.day.toLowerCase() == dayName).toList();
    todaySchedule.sort((a, b) => a.startTime.compareTo(b.startTime));
    return todaySchedule;
  }

  /// Get schedule for a specific day (sorted by time)
  List<ScheduleEntry> getScheduleForDay(int weekday) {
    final dayName = _getDayName(weekday).toLowerCase();
    final daySchedule = _schedule.where((entry) => entry.day.toLowerCase() == dayName).toList();
    daySchedule.sort((a, b) => a.startTime.compareTo(b.startTime));
    return daySchedule;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  void clear() {
    _schedule = [];
    _error = null;
    notifyListeners();
  }
}
