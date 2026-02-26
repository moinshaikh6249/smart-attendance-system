import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';

class StudentProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Student> _students = [];
  List<Student> _pendingApprovals = [];
  bool _loading = false;
  String? _error;

  List<Student> get students => _students;
  List<Student> get pendingApprovals => _pendingApprovals;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadStudents(String schoolId, String classId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _firebaseService.fetchStudents(schoolId, classId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStudents() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _firebaseService.fetchAllStudents();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingApprovals() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingApprovals = await _firebaseService.fetchPendingApprovals();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> approveStudent(Student student) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.approveStudent(student.uuid);
      // Remove from pending approvals list
      _pendingApprovals.removeWhere((s) => s.uuid == student.uuid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 