import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model for internal assessment mark entry
class InternalMarkEntry {
  final String id;
  final String subjectName;
  final String subjectCode;
  final String examComponent; // IA1, IA2, Assignment, Practical, etc.
  final double maxMarks;
  final double marksObtained;
  final double? weightage;
  final String? semester;
  final String? academicYear;
  final DateTime? examDate;

  InternalMarkEntry({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.examComponent,
    required this.maxMarks,
    required this.marksObtained,
    this.weightage,
    this.semester,
    this.academicYear,
    this.examDate,
  });

  factory InternalMarkEntry.fromMap(Map<dynamic, dynamic> map, String id) {
    return InternalMarkEntry(
      id: id,
      subjectName: map['subjectName']?.toString() ?? map['subject']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      examComponent: map['examComponent']?.toString() ?? map['component']?.toString() ?? 'IA',
      maxMarks: (map['maxMarks'] ?? 0).toDouble(),
      marksObtained: (map['marksObtained'] ?? map['marks'] ?? 0).toDouble(),
      weightage: map['weightage'] != null ? (map['weightage']).toDouble() : null,
      semester: map['semester']?.toString(),
      academicYear: map['academicYear']?.toString(),
      examDate: map['examDate'] != null 
          ? DateTime.tryParse(map['examDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'examComponent': examComponent,
      'maxMarks': maxMarks,
      'marksObtained': marksObtained,
      'weightage': weightage,
      'semester': semester,
      'academicYear': academicYear,
      'examDate': examDate?.toIso8601String(),
    };
  }

  factory InternalMarkEntry.fromJson(Map<String, dynamic> json) {
    return InternalMarkEntry(
      id: json['id'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      examComponent: json['examComponent'] ?? 'IA',
      maxMarks: (json['maxMarks'] ?? 0).toDouble(),
      marksObtained: (json['marksObtained'] ?? 0).toDouble(),
      weightage: json['weightage'] != null ? (json['weightage']).toDouble() : null,
      semester: json['semester'],
      academicYear: json['academicYear'],
      examDate: json['examDate'] != null 
          ? DateTime.tryParse(json['examDate'])
          : null,
    );
  }

  double get percentage => maxMarks > 0 ? (marksObtained / maxMarks) * 100 : 0;
}

/// Model for subject-wise internal marks summary
class SubjectInternalMarks {
  final String subjectName;
  final String subjectCode;
  final List<InternalMarkEntry> marks;

  SubjectInternalMarks({
    required this.subjectName,
    required this.subjectCode,
    required this.marks,
  });

  double get totalMarksObtained => marks.fold(0, (sum, mark) => sum + mark.marksObtained);
  double get totalMaxMarks => marks.fold(0, (sum, mark) => sum + mark.maxMarks);
  double get percentage => totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0;
}

/// Provider for internal assessment marks
class InternalMarksProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  List<InternalMarkEntry> _marks = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedSemester;
  DateTime? _lastUpdated;
  bool _isFromCache = false;

  List<InternalMarkEntry> get marks => _marks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedSemester => _selectedSemester;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isFromCache => _isFromCache;

  static const String _cacheKey = 'internal_marks_cache';
  static const String _cacheTimestampKey = 'internal_marks_cache_timestamp';

  /// Load cached marks
  Future<void> loadCachedMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cachedTimestamp != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        _marks = jsonList.map((json) => InternalMarkEntry.fromJson(json)).toList();
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
        _isFromCache = true;
        notifyListeners();
        print('[InternalMarksProvider] Loaded from cache: ${_marks.length} entries');
      }
    } catch (e) {
      print('[InternalMarksProvider] Cache load error: $e');
    }
  }

  /// Save marks to cache
  Future<void> _saveToCache(List<InternalMarkEntry> marks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = marks.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('[InternalMarksProvider] Saved to cache: ${marks.length} entries');
    } catch (e) {
      print('[InternalMarksProvider] Cache save error: $e');
    }
  }

  /// Fetch internal marks from Firebase
  Future<void> fetchMarks({
    required String schoolId,
    required String studentUUID,
    bool showLoading = true,
    String? semester,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    // Load from cache first if available
    if (_marks.isEmpty) {
      await loadCachedMarks();
    }

    _selectedSemester = semester;

    try {
      // Build path with optional semester filter
      String path = 'internalMarks/$schoolId/students/$studentUUID';
      if (semester != null) {
        path += '/$semester';
      }

      final snapshot = await _db
          .ref(path)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout: Unable to load internal marks. Please check your network connection.');
            },
          );

      if (snapshot.exists) {
        final data = snapshot.value;
        final entries = <InternalMarkEntry>[];

        if (data is List) {
          for (var i = 0; i < data.length; i++) {
            if (data[i] != null) {
              entries.add(InternalMarkEntry.fromMap(data[i], i.toString()));
            }
          }
        } else if (data is Map) {
          data.forEach((key, value) {
            if (value != null) {
              entries.add(InternalMarkEntry.fromMap(value, key.toString()));
            }
          });
        }

        _marks = entries;
        _lastUpdated = DateTime.now();
        _isFromCache = false;
        _error = null;

        // Save to cache
        await _saveToCache(entries);
      } else {
        // No data on server
        if (_marks.isEmpty) {
          _marks = [];
          _error = null; // Not an error, just no data
        }
      }
    } catch (e) {
      // If we have cached data, keep showing it
      if (_marks.isEmpty) {
        _error = e.toString();
      } else {
        _error = 'Showing last updated marks. Couldn\'t refresh right now.';
      }
      print('[InternalMarksProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get marks grouped by subject
  Map<String, SubjectInternalMarks> getMarksBySubject() {
    final Map<String, List<InternalMarkEntry>> grouped = {};
    
    for (var mark in _marks) {
      final key = mark.subjectCode.isNotEmpty ? mark.subjectCode : mark.subjectName;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(mark);
    }

    return grouped.map((key, marks) => MapEntry(
      key,
      SubjectInternalMarks(
        subjectName: marks.first.subjectName,
        subjectCode: marks.first.subjectCode,
        marks: marks,
      ),
    ));
  }

  /// Get marks grouped by exam component
  Map<String, List<InternalMarkEntry>> getMarksByComponent() {
    final Map<String, List<InternalMarkEntry>> grouped = {};
    
    for (var mark in _marks) {
      if (!grouped.containsKey(mark.examComponent)) {
        grouped[mark.examComponent] = [];
      }
      grouped[mark.examComponent]!.add(mark);
    }

    return grouped;
  }

  /// Get total marks across all subjects
  double get totalMarksObtained => _marks.fold(0, (sum, mark) => sum + mark.marksObtained);
  double get totalMaxMarks => _marks.fold(0, (sum, mark) => sum + mark.maxMarks);
  double get overallPercentage => totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0;

  void clear() {
    _marks = [];
    _error = null;
    notifyListeners();
  }
}
