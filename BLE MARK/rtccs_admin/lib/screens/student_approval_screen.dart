import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/school_provider.dart';
import '../widgets/student_profile_picture.dart';
import '../theme.dart';
import '../widgets/branded_app_bar.dart';
import '../widgets/bottom_nav.dart';
import '../services/firebase_service.dart';

class StudentApprovalScreen extends StatefulWidget {
  const StudentApprovalScreen({Key? key}) : super(key: key);

  @override
  State<StudentApprovalScreen> createState() => _StudentApprovalScreenState();
}

class _StudentApprovalScreenState extends State<StudentApprovalScreen> {
  int navIndex = 2;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, String> _schoolNames = {};
  Map<String, String> _classNames = {};
  Map<String, String> _subjectNames = {};

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
    _loadSchoolClassSubjectNames();
  }

  Future<void> _loadPendingApprovals() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await studentProvider.loadPendingApprovals();
  }

  Future<void> _loadSchoolClassSubjectNames() async {
    try {
      // Load all schools
      final schools = await _firebaseService.fetchSchools();
      for (var school in schools) {
        _schoolNames[school.id] = school.name;
      }

      // Load all classes and subjects
      for (var school in schools) {
        final classes = await _firebaseService.fetchClasses(school.id);
        for (var classroom in classes) {
          _classNames[classroom.id] = classroom.name;
          final subjects = await _firebaseService.fetchSubjects(school.id, classroom.id);
          for (var subject in subjects) {
            _subjectNames[subject.id] = subject.name;
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading school/class/subject names: $e');
    }
  }

  String _getSchoolName(String? schoolId) {
    if (schoolId == null) return 'Unknown School';
    return _schoolNames[schoolId] ?? schoolId;
  }

  String _getClassName(String? classId) {
    if (classId == null) return 'Unknown Class';
    return _classNames[classId] ?? classId;
  }

  String _getSubjectName(String? subjectId) {
    if (subjectId == null) return 'Unknown Subject';
    return _subjectNames[subjectId] ?? subjectId;
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final pending = studentProvider.pendingApprovals;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 48.0 : 16.0;
    final verticalPadding = isTablet ? 32.0 : 16.0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrandedAppBar(title: 'Student Approvals'),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: studentProvider.loading && pending.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : pending.isEmpty
                  ? const Center(child: Text('No pending approvals'))
                  : ListView.builder(
                  itemCount: pending.length,
                  itemBuilder: (context, i) {
                    final student = pending[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StudentProfilePicture(photoUrl: student.profilePhotoUrl),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (student.email != null && student.email!.isNotEmpty)
                                        Text(
                                          student.email!,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty)
                                        Text(
                                          student.phoneNumber!,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  child: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: studentProvider.loading
                                      ? null
                                      : () async {
                                          await studentProvider.approveStudent(student);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Approved ${student.name}')),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.school, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'School: ${_getSchoolName(student.schoolId)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.class_, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Class: ${_getClassName(student.classId)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.book, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Subject: ${_getSubjectName(student.subjectId)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: navIndex,
          onTap: (i) {
            setState(() => navIndex = i);
            // Add navigation logic for each tab if needed
          },
        ),
      ),
    );
  }
} 