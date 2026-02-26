import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../providers/class_provider.dart';
import '../providers/subject_provider.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  
  String? _selectedSchoolId;
  String? _selectedClassId;
  String? _selectedSubjectId;
  String _fullName = '';
  String _phoneNumber = '';
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
    await schoolProvider.loadSchools();
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final uuid = _uuid.v4();
      final firebaseService = FirebaseService();
      
      // Save to Firebase
      await firebaseService.registerStudent(
        uuid: uuid,
        name: _fullName,
        phoneNumber: _phoneNumber,
        schoolId: _selectedSchoolId!,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
      );

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('student_uuid', uuid);
      await prefs.setString('student_name', _fullName);
      await prefs.setString('student_phone', _phoneNumber);
      await prefs.setString('student_school', _selectedSchoolId!);
      await prefs.setString('student_class', _selectedClassId!);
      await prefs.setString('student_subject', _selectedSubjectId!);

      setState(() {
        _success = 'Registration request submitted! Your request is pending admin approval. Your UUID: $uuid';
      });

      // Note: Student cannot access dashboard until approved
      // They should see a pending approval message
      // For now, we'll just show success message
      // In a real app, you might want to show a "waiting for approval" screen

    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final classProvider = context.watch<ClassProvider>();
    final subjectProvider = context.watch<SubjectProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('New Student Registration'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Information',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // School Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedSchoolId,
                          decoration: const InputDecoration(
                            labelText: 'School',
                            prefixIcon: Icon(Icons.school),
                          ),
                          items: schoolProvider.schools.map((school) => DropdownMenuItem(
                            value: school.id,
                            child: Text(school.name),
                          )).toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedSchoolId = value;
                              _selectedClassId = null;
                              _selectedSubjectId = null;
                            });
                            if (value != null) {
                              await classProvider.loadClasses(value);
                            }
                          },
                          validator: (value) => value == null ? 'Please select a school' : null,
                        ),

                        const SizedBox(height: 16),

                        // Class Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: classProvider.classes.map((classroom) => DropdownMenuItem(
                            value: classroom.id,
                            child: Text(classroom.name),
                          )).toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedClassId = value;
                              _selectedSubjectId = null;
                            });
                            if (value != null && _selectedSchoolId != null) {
                              await subjectProvider.loadSubjects(_selectedSchoolId!, value);
                            }
                          },
                          validator: (value) => value == null ? 'Please select a class' : null,
                        ),

                        const SizedBox(height: 16),

                        // Subject Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedSubjectId,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            prefixIcon: Icon(Icons.book),
                          ),
                          items: subjectProvider.subjects.map((subject) => DropdownMenuItem(
                            value: subject.id,
                            child: Text(subject.name),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubjectId = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a subject' : null,
                        ),

                        const SizedBox(height: 16),

                        // Full Name
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          onChanged: (value) => _fullName = value,
                          validator: (value) => value?.isEmpty == true ? 'Please enter your full name' : null,
                        ),

                        const SizedBox(height: 16),

                        // Phone Number
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => _phoneNumber = value,
                          validator: (value) => value?.isEmpty == true ? 'Please enter your phone number' : null,
                        ),

                        const SizedBox(height: 24),

                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),

                        if (_success != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              _success!,
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerStudent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 