import 'package:flutter/material.dart';
import '../models/classroom.dart';
import '../services/firebase_service.dart';

class ClassProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Classroom> _classes = [];
  Classroom? _selectedClass;

  List<Classroom> get classes => _classes;
  Classroom? get selectedClass => _selectedClass;

  Future<void> loadClasses(String schoolId) async {
    _classes = await _firebaseService.fetchClasses(schoolId);
    notifyListeners();
  }

  void selectClass(Classroom classroom) {
    _selectedClass = classroom;
    notifyListeners();
  }
} 