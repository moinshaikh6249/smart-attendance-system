import 'package:flutter/material.dart';
import '../models/school.dart';
import '../services/firebase_service.dart';

class SchoolProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<School> _schools = [];
  School? _selectedSchool;

  List<School> get schools => _schools;
  School? get selectedSchool => _selectedSchool;

  Future<void> loadSchools() async {
    _schools = await _firebaseService.fetchSchools();
    notifyListeners();
  }

  void selectSchool(School school) {
    _selectedSchool = school;
    notifyListeners();
  }
} 