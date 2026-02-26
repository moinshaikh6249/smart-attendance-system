import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<AttendanceRecord> _attendance = [];
  bool _isOffline = false;
  String? _error;
  String? _success;

  AttendanceProvider() {
    _initConnectivity();
  }

  List<AttendanceRecord> get attendance => _attendance;
  bool get isOffline => _isOffline;
  String? get error => _error;
  String? get success => _success;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAttendance(String studentUUID) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendance = await _firebaseService.fetchAttendanceLogs(studentUUID);
      // Sort by timestamp descending (newest first)
      _attendance.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      _error = 'Failed to fetch attendance: $e';
      print('[AttendanceProvider] Error fetching attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initConnectivity() async {
    Connectivity().onConnectivityChanged.listen((result) async {
      _isOffline = result == ConnectivityResult.none;
      notifyListeners();
      if (!_isOffline) {
        await syncOfflineAttendance();
      }
    });
  }

  Future<void> addAttendance(AttendanceRecord record) async {
    _error = null;
    _success = null;
    if (_isOffline) {
      await _saveOffline(record);
      _success = 'Attendance saved offline. Will sync when online.';
    } else {
      try {
        await _firebaseService.saveAttendance(record);
        _success = 'Attendance marked successfully!';
      } catch (e) {
        _error = 'Failed to mark attendance: $e';
        print('[AttendanceProvider] Error saving attendance: $e');
      }
    }
    // Add to local list and sort by timestamp (newest first)
    _attendance.insert(0, record);
    notifyListeners();
  }

  Future<void> _saveOffline(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offline = prefs.getStringList('offline_attendance') ?? [];
    offline.add(jsonEncode(record.toMap()));
    await prefs.setStringList('offline_attendance', offline);
  }

  Future<void> syncOfflineAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offline = prefs.getStringList('offline_attendance') ?? [];
    for (final item in offline) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final record = AttendanceRecord.fromMap(map);
      try {
        await _firebaseService.saveAttendance(record);
      } catch (_) {}
      _attendance.add(record);
    }
    await prefs.remove('offline_attendance');
    notifyListeners();
  }
} 