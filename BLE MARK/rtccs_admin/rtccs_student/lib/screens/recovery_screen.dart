import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../providers/class_provider.dart';
import '../providers/subject_provider.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  
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

  Future<void> _recoverUUID() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final firebaseService = FirebaseService();
      
      // Query Firebase for matching student
      final student = await firebaseService.recoverStudentUUID(
        name: _fullName,
        phoneNumber: _phoneNumber,
        schoolId: _selectedSchoolId!,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
      );

      if (student != null) {
        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_uuid', student.uuid);
        await prefs.setString('student_name', student.name);
        await prefs.setString('student_phone', _phoneNumber);
        await prefs.setString('student_school', _selectedSchoolId!);
        await prefs.setString('student_class', _selectedClassId!);
        await prefs.setString('student_subject', _selectedSubjectId!);

        setState(() {
          _success = 'UUID recovered successfully! Your UUID: ${student.uuid}';
        });

        // Navigate to main navigation after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/main');
          }
        });
      } else {
        setState(() {
          _error = 'No student found with the provided details. Please check your information and try again.';
        });
      }

    } catch (e) {
      setState(() {
        _error = 'Recovery failed: $e';
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
          title: const Text('Recover UUID'),
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
                        Row(
                          children: [
                            Icon(Icons.key, color: Colors.green.shade600, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Recover Your UUID',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your details to recover your UUID',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
                            onPressed: _isLoading ? null : _recoverUUID,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Recover UUID'),
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