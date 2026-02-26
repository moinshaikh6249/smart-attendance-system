import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../services/firebase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<AttendanceRecord> _attendance = [];
  int _liveCount = 0;
  bool _isOffline = false;
  bool _loading = false;
  String? _error;

  AttendanceProvider() {
    _initConnectivity();
  }

  List<AttendanceRecord> get attendance => _attendance;
  int get liveCount => _liveCount;
  bool get isOffline => _isOffline;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _initConnectivity() async {
    Connectivity().onConnectivityChanged.listen((result) async {
      _isOffline = result == ConnectivityResult.none;
      notifyListeners();
      if (!_isOffline) {
        await syncOfflineAttendance();
      }
    });
  }

  Future<void> loadAttendanceRecords({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String date,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _attendance = await _firebaseService.fetchAttendanceRecords(
        schoolId,
        classId,
        subjectId,
        date,
      );
      _attendance.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _liveCount = _attendance.length;
    } catch (e) {
      _error = 'Failed to load attendance: $e';
      print('[AttendanceProvider] Error loading attendance: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addAttendance(AttendanceRecord record) async {
    if (_isOffline) {
      await _saveOffline(record);
    } else {
      await _firebaseService.saveAttendance(record);
    }
    _attendance.add(record);
    _liveCount++;
    notifyListeners();
  }

  Future<void> addAttendanceByDevice(String deviceId) async {
    final record = AttendanceRecord(
      studentUUID: deviceId,
      schoolID: 'demo_school',
      classID: 'demo_class',
      subjectID: 'demo_subject',
      date: DateTime.now().toIso8601String().substring(0, 10),
      method: 'BLE',
      facePhotoUrl: null,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await addAttendance(record);
  }

  Future<void> _saveOffline(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offline =
        prefs.getStringList('offline_attendance') ?? [];
    offline.add(jsonEncode(record.toMap()));
    await prefs.setStringList('offline_attendance', offline);
  }

  Future<void> syncOfflineAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offline =
        prefs.getStringList('offline_attendance') ?? [];
    for (final item in offline) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final record = AttendanceRecord.fromMap(map);
      await _firebaseService.saveAttendance(record);
      _attendance.add(record);
      _liveCount++;
    }
    await prefs.remove('offline_attendance');
    notifyListeners();
  }

  void setLiveCount(int count) {
    _liveCount = count;
    notifyListeners();
  }

  void clearAttendance() {
    _attendance = [];
    _liveCount = 0;
    notifyListeners();
  }
}
