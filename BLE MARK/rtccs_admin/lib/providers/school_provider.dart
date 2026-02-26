import 'package:flutter/material.dart';
import '../models/school.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../services/firebase_service.dart';

class SchoolProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<School> _schools = [];
  School? _selectedSchool;
  List<Classroom> _classes = [];
  Classroom? _selectedClass;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  List<School> get schools => _schools;
  School? get selectedSchool => _selectedSchool;
  List<Classroom> get classes => _classes;
  Classroom? get selectedClass => _selectedClass;
  List<Subject> get subjects => _subjects;
  Subject? get selectedSubject => _selectedSubject;

  Future<void> loadSchools() async {
    _schools = await _firebaseService.fetchSchools();
    notifyListeners();
  }

  Future<void> selectSchool(School school) async {
    _selectedSchool = school;
    _classes = await _firebaseService.fetchClasses(school.id);
    _selectedClass = null;
    _subjects = [];
    _selectedSubject = null;
    notifyListeners();
  }

  Future<void> selectClass(Classroom classroom) async {
    _selectedClass = classroom;
    if (_selectedSchool != null && _selectedClass != null) {
      _subjects = await _firebaseService.fetchSubjects(_selectedSchool!.id, _selectedClass!.id);
    } else {
      _subjects = [];
    }
    _selectedSubject = null;
    notifyListeners();
  }

  void selectSubject(Subject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }
} 