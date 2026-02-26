import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Model for Hall Ticket data
class HallTicket {
  final String id;
  final String studentName;
  final String enrollmentNo;
  final String? prn;
  final String seatNumber;
  final String examName;
  final String program;
  final String semester;
  final String examCenterName;
  final String? centerCode;
  final List<String> examDates;
  final String? pdfUrl;
  final String? imageUrl;
  final bool isReleased;
  final DateTime? releaseDate;
  final Map<String, dynamic>? additionalInfo;

  HallTicket({
    required this.id,
    required this.studentName,
    required this.enrollmentNo,
    this.prn,
    required this.seatNumber,
    required this.examName,
    required this.program,
    required this.semester,
    required this.examCenterName,
    this.centerCode,
    required this.examDates,
    this.pdfUrl,
    this.imageUrl,
    required this.isReleased,
    this.releaseDate,
    this.additionalInfo,
  });

  factory HallTicket.fromMap(String id, Map<dynamic, dynamic> map) {
    final examDatesList = <String>[];
    if (map['examDates'] != null) {
      if (map['examDates'] is List) {
        examDatesList.addAll((map['examDates'] as List).map((e) => e.toString()));
      } else if (map['examDates'] is String) {
        examDatesList.add(map['examDates'].toString());
      }
    }

    return HallTicket(
      id: id,
      studentName: map['studentName']?.toString() ?? '',
      enrollmentNo: map['enrollmentNo']?.toString() ?? '',
      prn: map['prn']?.toString(),
      seatNumber: map['seatNumber']?.toString() ?? '',
      examName: map['examName']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      semester: map['semester']?.toString() ?? '',
      examCenterName: map['examCenterName']?.toString() ?? '',
      centerCode: map['centerCode']?.toString(),
      examDates: examDatesList,
      pdfUrl: map['pdfUrl']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      isReleased: map['isReleased'] == true,
      releaseDate: map['releaseDate'] != null 
          ? DateTime.tryParse(map['releaseDate'].toString())
          : null,
      additionalInfo: map['additionalInfo'] != null 
          ? Map<String, dynamic>.from(map['additionalInfo'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'enrollmentNo': enrollmentNo,
      'prn': prn,
      'seatNumber': seatNumber,
      'examName': examName,
      'program': program,
      'semester': semester,
      'examCenterName': examCenterName,
      'centerCode': centerCode,
      'examDates': examDates,
      'pdfUrl': pdfUrl,
      'imageUrl': imageUrl,
      'isReleased': isReleased,
      'releaseDate': releaseDate?.toIso8601String(),
      'additionalInfo': additionalInfo,
    };
  }

  bool get hasDownloadableContent => pdfUrl != null || imageUrl != null;
  
  String get displayId => prn ?? enrollmentNo;
  
  String get formattedExamDates {
    if (examDates.isEmpty) return 'Not specified';
    if (examDates.length == 1) return examDates.first;
    return '${examDates.first} to ${examDates.last}';
  }
}

class HallTicketProvider with ChangeNotifier {
  HallTicket? _hallTicket;
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;
  String? _cachedPdfPath;

  HallTicket? get hallTicket => _hallTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFromCache => _isFromCache;
  String? get cachedPdfPath => _cachedPdfPath;

  bool get hasHallTicket => _hallTicket != null;
  bool get isReleased => _hallTicket?.isReleased ?? false;
  bool get canDownload => isReleased && (_hallTicket?.hasDownloadableContent ?? false);

  /// Load cached hall ticket
  Future<void> loadCachedHallTicket(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'hall_ticket_${schoolId}_$studentUUID';
      final cachedData = prefs.getString(key);

      if (cachedData != null) {
        final Map<String, dynamic> decoded = json.decode(cachedData);
        _hallTicket = HallTicket.fromMap(decoded['id'], decoded);
        _isFromCache = true;
        
        // Check for cached PDF path
        final pdfPathKey = 'hall_ticket_pdf_path_${schoolId}_$studentUUID';
        _cachedPdfPath = prefs.getString(pdfPathKey);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached hall ticket: $e');
    }
  }

  /// Fetch hall ticket from Firebase
  Future<void> fetchHallTicket({
    required String schoolId,
    required String studentUUID,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Load from cache first
      await loadCachedHallTicket(schoolId, studentUUID);

      final db = FirebaseDatabase.instance;
      final ref = db.ref('schools/$schoolId/students/$studentUUID/hallTicket');

      // Set timeout
      final dataSnapshot = await ref.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (dataSnapshot.exists) {
        final Map<dynamic, dynamic> data = dataSnapshot.value as Map<dynamic, dynamic>;
        
        // The data could be a single hall ticket or the latest one
        // Assuming single hall ticket per student for current exam
        _hallTicket = HallTicket.fromMap(studentUUID, data);
        _isFromCache = false;
        _error = null;

        // Cache the data
        await _cacheHallTicket(schoolId, studentUUID);
      } else {
        _hallTicket = null;
        _error = null; // No error, just not available yet
      }
    } on TimeoutException catch (_) {
      _error = 'Request timed out. Showing cached data.';
      debugPrint('Hall ticket fetch timeout');
    } catch (e) {
      _error = 'Failed to load hall ticket: ${e.toString()}';
      debugPrint('Error fetching hall ticket: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache hall ticket data
  Future<void> _cacheHallTicket(String schoolId, String studentUUID) async {
    try {
      if (_hallTicket == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final key = 'hall_ticket_${schoolId}_$studentUUID';
      await prefs.setString(key, json.encode(_hallTicket!.toMap()));
      
      // Save timestamp
      await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching hall ticket: $e');
    }
  }

  /// Save cached PDF path
  Future<void> saveCachedPdfPath(String schoolId, String studentUUID, String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'hall_ticket_pdf_path_${schoolId}_$studentUUID';
      await prefs.setString(key, path);
      _cachedPdfPath = path;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving PDF path: $e');
    }
  }

  /// Clear cache
  Future<void> clearCache(String schoolId, String studentUUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'hall_ticket_${schoolId}_$studentUUID';
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
      await prefs.remove('hall_ticket_pdf_path_${schoolId}_$studentUUID');
      _cachedPdfPath = null;
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear current data
  void clear() {
    _hallTicket = null;
    _isLoading = false;
    _error = null;
    _isFromCache = false;
    _cachedPdfPath = null;
    notifyListeners();
  }
}
