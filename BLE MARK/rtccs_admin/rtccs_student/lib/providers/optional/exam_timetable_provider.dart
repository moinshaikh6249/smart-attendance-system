import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Model for a single exam entry
class ExamEntry {
  final String id;
  final String examName;
  final String subjectName;
  final String subjectCode;
  final DateTime examDate;
  final String startTime; // HH:MM format
  final String endTime; // HH:MM format
  final String examType; // Theory, Practical, Viva
  final String? roomOrCenter;
  final String? seatNumber;

  ExamEntry({
    required this.id,
    required this.examName,
    required this.subjectName,
    required this.subjectCode,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.examType,
    this.roomOrCenter,
    this.seatNumber,
  });

  factory ExamEntry.fromMap(String id, Map<dynamic, dynamic> map) {
    return ExamEntry(
      id: id,
      examName: map['examName']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      examDate: DateTime.parse(map['examDate']?.toString() ?? DateTime.now().toString()),
      startTime: map['startTime']?.toString() ?? '00:00',
      endTime: map['endTime']?.toString() ?? '00:00',
      examType: map['examType']?.toString() ?? 'Theory',
      roomOrCenter: map['roomOrCenter']?.toString(),
      seatNumber: map['seatNumber']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examName': examName,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'examDate': examDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'examType': examType,
      'roomOrCenter': roomOrCenter,
      'seatNumber': seatNumber,
    };
  }

  bool get isUpcoming => examDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  bool get isPast => !isUpcoming;

  DateTime get examDateTime {
    try {
      final timeParts = startTime.split(':');
      return DateTime(
        examDate.year,
        examDate.month,
        examDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return examDate;
    }
  }
}

class ExamTimetableProvider with ChangeNotifier {
  List<ExamEntry> _exams = [];
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;

  List<ExamEntry> get exams => _exams;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;

  // Filtered lists
  List<ExamEntry> get upcomingExams => _exams.where((e) => e.isUpcoming).toList();
  List<ExamEntry> get pastExams => _exams.where((e) => e.isPast).toList();

  // Get exams by type
  List<ExamEntry> getExamsByType(String type) {
    if (type.toLowerCase() == 'all') return _exams;
    return _exams.where((e) => e.examType.toLowerCase() == type.toLowerCase()).toList();
  }

  // Get exams by date range
  List<ExamEntry> getExamsByDateRange(DateTime start, DateTime end) {
    return _exams.where((e) {
      return e.examDate.isAfter(start.subtract(const Duration(days: 1))) &&
          e.examDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Load cached exam timetable
  Future<void> loadCachedExams(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_timetable_${schoolId}_$studentUUID';
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        _exams = decoded.map((e) => ExamEntry.fromMap(e['id'], e)).toList();
        _sortExams();
        _isFromCache = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached exam timetable: $e');
    }
  }

  /// Fetch exam timetable from Firebase
  Future<void> fetchExamTimetable({
    required String schoolId,
    required String studentUUID,
    String? program,
    String? semester,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Load from cache first
      await loadCachedExams(schoolId, studentUUID);

      final db = FirebaseDatabase.instance;
      final ref = db.ref('schools/$schoolId/students/$studentUUID/examTimetable');

      // Set timeout
      final dataSnapshot = await ref.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (dataSnapshot.exists) {
        final Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
        final List<ExamEntry> fetchedExams = [];

        data.forEach((key, value) {
          if (value is Map) {
            try {
              fetchedExams.add(ExamEntry.fromMap(key.toString(), value));
            } catch (e) {
              debugPrint('Error parsing exam entry $key: $e');
            }
          }
        });

        _exams = fetchedExams;
        _sortExams();
        _isFromCache = false;
        _error = null;

        // Cache the data
        await _cacheExams(schoolId, studentUUID);
      } else {
        _exams = [];
        _error = null;
      }
    } on TimeoutException catch (_) {
      _error = 'Request timed out. Showing cached data.';
      debugPrint('Exam timetable fetch timeout');
    } catch (e) {
      _error = 'Failed to load exam timetable: ${e.toString()}';
      debugPrint('Error fetching exam timetable: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache exam timetable data
  Future<void> _cacheExams(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_timetable_${schoolId}_$studentUUID';
      final data = _exams.map((e) => e.toMap()).toList();
      await prefs.setString(key, json.encode(data));
      
      // Save timestamp
      await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching exam timetable: $e');
    }
  }

  /// Sort exams by date and time
  void _sortExams() {
    _exams.sort((a, b) {
      // Primary: examDate ascending
      final dateComparison = a.examDate.compareTo(b.examDate);
      if (dateComparison != 0) return dateComparison;

      // Secondary: startTime ascending
      return a.startTime.compareTo(b.startTime);
    });
  }

  /// Clear cache
  Future<void> clearCache(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_timetable_${schoolId}_$studentUUID';
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get next upcoming exam
  ExamEntry? get nextExam {
    final upcoming = upcomingExams;
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  /// Get exam count by type
  Map<String, int> get examCountByType {
    final counts = <String, int>{};
    for (var exam in _exams) {
      counts[exam.examType] = (counts[exam.examType] ?? 0) + 1;
    }
    return counts;
  }
}
