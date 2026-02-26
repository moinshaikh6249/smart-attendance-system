import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for exam result / semester result
class ExamResult {
  final String examName;
  final String semester;
  final String semesterCode;
  final Map<String, SubjectResult> subjects;
  final double totalMarks;
  final double obtainedMarks;
  final double percentage;
  final String grade;
  final String status; // Pass, Fail, Withheld, Pending
  final DateTime? publishedDate;
  final double? sgpa; // Semester Grade Point Average
  final double? cgpa; // Cumulative Grade Point Average
  final int? totalCreditsEarned;
  final String? academicYear;
  final bool isPublished;

  ExamResult({
    required this.examName,
    required this.semester,
    required this.semesterCode,
    required this.subjects,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.percentage,
    required this.grade,
    required this.status,
    this.publishedDate,
    this.sgpa,
    this.cgpa,
    this.totalCreditsEarned,
    this.academicYear,
    this.isPublished = false,
  });

  factory ExamResult.fromMap(Map<dynamic, dynamic> map, [String? semesterKey]) {
    final subjects = <String, SubjectResult>{};
    if (map['subjects'] != null) {
      final subjectsMap = map['subjects'] as Map;
      subjectsMap.forEach((key, value) {
        subjects[key.toString()] = SubjectResult.fromMap(value);
      });
    }

    return ExamResult(
      examName: map['examName']?.toString() ?? map['semesterName']?.toString() ?? '',
      semester: map['semester']?.toString() ?? map['semesterName']?.toString() ?? '',
      semesterCode: map['semesterCode']?.toString() ?? semesterKey ?? '',
      subjects: subjects,
      totalMarks: (map['totalMarks'] ?? 0).toDouble(),
      obtainedMarks: (map['obtainedMarks'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      grade: map['grade']?.toString() ?? '',
      status: map['status']?.toString() ?? map['resultStatus']?.toString() ?? 'Pending',
      publishedDate: map['publishedDate'] != null
          ? DateTime.tryParse(map['publishedDate'].toString())
          : null,
      sgpa: map['sgpa'] != null ? (map['sgpa']).toDouble() : null,
      cgpa: map['cgpa'] != null ? (map['cgpa']).toDouble() : null,
      totalCreditsEarned: map['totalCreditsEarned'] != null
          ? int.tryParse(map['totalCreditsEarned'].toString())
          : null,
      academicYear: map['academicYear']?.toString(),
      isPublished: map['isPublished'] == true || map['published'] == true,
    );
  }

  int get totalCredits => subjects.values.fold(0, (sum, subject) => sum + (subject.credits ?? 0));
  int get passedSubjects => subjects.values.where((s) => s.passed).length;
  int get failedSubjects => subjects.values.where((s) => !s.passed).length;
}

/// Model for subject result
class SubjectResult {
  final String subjectName;
  final String subjectCode;
  final double maxMarks;
  final double obtainedMarks;
  final String grade;
  final bool passed;
  final double? gradePoints;
  final int? credits;
  final String? resultStatus; // Pass, Fail, Absent

  SubjectResult({
    required this.subjectName,
    this.subjectCode = '',
    required this.maxMarks,
    required this.obtainedMarks,
    required this.grade,
    required this.passed,
    this.gradePoints,
    this.credits,
    this.resultStatus,
  });

  factory SubjectResult.fromMap(Map<dynamic, dynamic> map) {
    final isPassed = map['passed'] == true || 
                     (map['resultStatus']?.toString().toLowerCase() == 'pass') ||
                     (map['status']?.toString().toLowerCase() == 'pass');
    
    return SubjectResult(
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      maxMarks: (map['maxMarks'] ?? 0).toDouble(),
      obtainedMarks: (map['obtainedMarks'] ?? map['marksObtained'] ?? 0).toDouble(),
      grade: map['grade']?.toString() ?? '',
      passed: isPassed,
      gradePoints: map['gradePoints'] != null ? (map['gradePoints']).toDouble() : null,
      credits: map['credits'] != null ? int.tryParse(map['credits'].toString()) : null,
      resultStatus: map['resultStatus']?.toString() ?? map['status']?.toString(),
    );
  }

  double get percentage => maxMarks > 0 ? (obtainedMarks / maxMarks) * 100 : 0;
}

/// Provider for exam results
class ResultsProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  List<ExamResult> _results = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  bool _isFromCache = false;

  List<ExamResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isFromCache => _isFromCache;

  static const String _cacheKey = 'results_cache';
  static const String _cacheTimestampKey = 'results_cache_timestamp';

  /// Load cached results
  Future<void> loadCachedResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        // Simple cache for now - would need proper JSON serialization
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        _isFromCache = true;
        notifyListeners();
        print('[ResultsProvider] Cache timestamp loaded');
      }
    } catch (e) {
      print('[ResultsProvider] Cache load error: $e');
    }
  }

  /// Fetch exam results from Firebase
  Future<void> fetchResults({
    required String schoolId,
    required String classId,
    required String studentUUID,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    // Load cache info first
    if (_results.isEmpty) {
      await loadCachedResults();
    }

    try {
      final snapshot = await _db
          .ref('results/$schoolId/students/$studentUUID')
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout: Unable to load results. Please check your network connection.');
            },
          );

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final results = <ExamResult>[];

        data.forEach((key, value) {
          if (value != null) {
            results.add(ExamResult.fromMap(value, key.toString()));
          }
        });

        // Sort by semester code/published date (newest first)
        results.sort((a, b) {
          // First try sorting by semester code
          final codeCompare = b.semesterCode.compareTo(a.semesterCode);
          if (codeCompare != 0) return codeCompare;
          
          // Then by published date
          if (a.publishedDate == null && b.publishedDate == null) return 0;
          if (a.publishedDate == null) return 1;
          if (b.publishedDate == null) return -1;
          return b.publishedDate!.compareTo(a.publishedDate!);
        });

        _results = results;
        _lastUpdated = DateTime.now();
        _isFromCache = false;
        _error = null;

        // Save timestamp to cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        } catch (e) {
          print('[ResultsProvider] Cache save error: $e');
        }
      } else {
        // No data on server
        if (_results.isEmpty) {
          _results = [];
          _error = null;
        }
      }
    } catch (e) {
      // If we have cached data, keep showing it
      if (_results.isEmpty) {
        _error = e.toString();
      } else {
        _error = 'Showing last updated results. Couldn\'t refresh right now.';
      }
      print('[ResultsProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get published results only
  List<ExamResult> get publishedResults => _results.where((r) => r.isPublished).toList();

  /// Get result for specific semester
  ExamResult? getResultForSemester(String semesterCode) {
    try {
      return _results.firstWhere((r) => r.semesterCode == semesterCode);
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _results = [];
    _error = null;
    notifyListeners();
  }
}
