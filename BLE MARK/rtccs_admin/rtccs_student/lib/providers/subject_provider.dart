import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/firebase_service.dart';

class SubjectProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  List<Subject> get subjects => _subjects;
  Subject? get selectedSubject => _selectedSubject;

  Future<void> loadSubjects(String schoolId, String classId) async {
    _subjects = await _firebaseService.fetchSubjects(schoolId, classId);
    notifyListeners();
  }

  void selectSubject(Subject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }
} 