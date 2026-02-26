import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/student_provider.dart';
import '../services/photo_service.dart';
import '../services/firebase_service.dart';
import '../services/excel_service.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../theme.dart';
import '../widgets/branded_app_bar.dart';
import '../widgets/bottom_nav.dart';
import 'package:intl/intl.dart';
import '../screens/ble_broadcast_page.dart';
import 'ble_diagnostics_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int navIndex = 1;
  DateTime selectedDate = DateTime.now();
  String? selectedClassId;
  String? selectedSubjectId;
  String searchQuery = '';
  final Set<String> _selectedManualStudents = {};
  bool _submittingManual = false;

  @override
  void initState() {
    super.initState();
    // Load schools data when attendance screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolProvider = Provider.of<SchoolProvider>(
        context,
        listen: false,
      );
      schoolProvider.loadSchools();
    });
  }

  String get _selectedDateKey => DateFormat('yyyy-MM-dd').format(selectedDate);

  Future<void> _syncAttendanceForSelection() async {
    final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final school = schoolProvider.selectedSchool;

    if (school == null ||
        selectedClassId == null ||
        selectedSubjectId == null) {
      attendanceProvider.clearAttendance();
      return;
    }

    await attendanceProvider.loadAttendanceRecords(
      schoolId: school.id,
      classId: selectedClassId!,
      subjectId: selectedSubjectId!,
      date: _selectedDateKey,
    );
  }

  bool _isStudentAlreadyMarked(
    String studentUuid,
    AttendanceProvider provider,
  ) {
    return provider.attendance.any(
      (record) =>
          record.studentUUID == studentUuid &&
          record.date == _selectedDateKey &&
          (selectedClassId == null || record.classID == selectedClassId) &&
          (selectedSubjectId == null || record.subjectID == selectedSubjectId),
    );
  }

  Future<void> _submitManualAttendance() async {
    if (_selectedManualStudents.isEmpty) return;

    final schoolProvider = context.read<SchoolProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final studentProvider = context.read<StudentProvider>();

    final school = schoolProvider.selectedSchool;
    if (school == null ||
        selectedClassId == null ||
        selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select school, class, and subject first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _submittingManual = true;
    });

    try {
      int markedCount = 0;
      for (final student in studentProvider.students) {
        if (!_selectedManualStudents.contains(student.uuid)) continue;
        if (_isStudentAlreadyMarked(student.uuid, attendanceProvider)) {
          continue;
        }

        final record = AttendanceRecord(
          studentUUID: student.uuid,
          schoolID: school.id,
          classID: selectedClassId!,
          subjectID: selectedSubjectId!,
          date: _selectedDateKey,
          method: 'Manual',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        await attendanceProvider.addAttendance(record);
        markedCount++;
      }

      if (!mounted) return;
      setState(() {
        _selectedManualStudents.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            markedCount > 0
                ? 'Manual attendance submitted for $markedCount student(s).'
                : 'Selected students were already marked present.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit manual attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingManual = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 48.0 : 16.0;
    final verticalPadding = isTablet ? 32.0 : 16.0;

    // Filter attendance by date, class, subject, and search
    final filteredAttendance = attendanceProvider.attendance.where((record) {
      final recordDate = DateTime.parse(record.date);
      final matchesDate =
          recordDate.year == selectedDate.year &&
          recordDate.month == selectedDate.month &&
          recordDate.day == selectedDate.day;
      final matchesClass =
          selectedClassId == null || record.classID == selectedClassId;
      final matchesSubject =
          selectedSubjectId == null || record.subjectID == selectedSubjectId;
      final student = studentProvider.students.firstWhere(
        (s) => s.uuid == record.studentUUID,
        orElse: () => Student(uuid: '', name: ''),
      );
      final matchesSearch =
          searchQuery.isEmpty ||
          student.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          record.studentUUID.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesDate && matchesClass && matchesSubject && matchesSearch;
    }).toList();

    final filteredStudentsForManual = studentProvider.students.where((student) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return student.name.toLowerCase().contains(query) ||
          student.uuid.toLowerCase().contains(query);
    }).toList();

    final hasCompleteSelection =
        schoolProvider.selectedSchool != null &&
        selectedClassId != null &&
        selectedSubjectId != null;

    Future<void> handleExport() async {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            margin: EdgeInsets.all(24),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting filtered attendance...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final schoolProvider = context.read<SchoolProvider>();
        final studentProvider = context.read<StudentProvider>();
        
        final result = await ExcelService().exportAttendanceToExcel(
          filteredAttendance,
          'attendance_filtered',
          className: schoolProvider.classes
              .firstWhere((c) => c.id == selectedClassId, orElse: () => Classroom(id: '', name: '', schoolId: ''))
              .name,
          subjectName: schoolProvider.subjects
              .firstWhere((s) => s.id == selectedSubjectId, orElse: () => Subject(id: '', name: '', classId: ''))
              .name,
          studentsList: studentProvider.students,
          adminName: 'Admin',
          instituteName: schoolProvider.selectedSchool?.name,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ File saved: ${result.fileName}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Export failed'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrandedAppBar(title: 'Take Attendance'),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date picker and dropdowns
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          await _syncAttendanceForSelection();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // School dropdown
                DropdownButtonFormField<String>(
                  value: schoolProvider.selectedSchool?.id,
                  items: schoolProvider.schools
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      final school = schoolProvider.schools.firstWhere(
                        (s) => s.id == val,
                      );
                      await schoolProvider.selectSchool(school);
                      setState(() {
                        selectedClassId = null;
                        selectedSubjectId = null;
                      });
                      context.read<AttendanceProvider>().clearAttendance();
                    }
                  },
                  decoration: const InputDecoration(labelText: 'School'),
                ),
                const SizedBox(height: 16),
                // Class and Subject dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedClassId,
                        items: schoolProvider.classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedClassId = val;
                            selectedSubjectId = null;
                          });
                          context.read<AttendanceProvider>().clearAttendance();
                          if (val != null &&
                              schoolProvider.selectedSchool != null) {
                            final classroom = schoolProvider.classes.firstWhere(
                              (c) => c.id == val,
                            );
                            await schoolProvider.selectClass(classroom);
                            await studentProvider.loadStudents(
                              schoolProvider.selectedSchool!.id,
                              val,
                            );
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Class'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        items: schoolProvider.subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) async {
                          setState(() => selectedSubjectId = val);
                          context.read<AttendanceProvider>().clearAttendance();
                          if (val != null) {
                            final subject = schoolProvider.subjects.firstWhere(
                              (s) => s.id == val,
                            );
                            schoolProvider.selectSubject(subject);
                            await _syncAttendanceForSelection();
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search student name or UUID',
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                ),
                const SizedBox(height: 16),
                // Export button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export List'),
                    onPressed: handleExport,
                  ),
                ),
                const SizedBox(height: 16),
                // Selection status indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selection Status:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            schoolProvider.selectedSchool != null
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: schoolProvider.selectedSchool != null
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'School: ${schoolProvider.selectedSchool?.name ?? 'Not selected'}',
                            style: TextStyle(
                              color: schoolProvider.selectedSchool != null
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            schoolProvider.selectedClass != null
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: schoolProvider.selectedClass != null
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Class: ${schoolProvider.selectedClass?.name ?? 'Not selected'}',
                            style: TextStyle(
                              color: schoolProvider.selectedClass != null
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            schoolProvider.selectedSubject != null
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: schoolProvider.selectedSubject != null
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Subject: ${schoolProvider.selectedSubject?.name ?? 'Not selected'}',
                            style: TextStyle(
                              color: schoolProvider.selectedSubject != null
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mark Attendance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (attendanceProvider.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.qr_code_2,
                      label: 'Generate QR',
                      onTap: () {
                        Navigator.of(context).pushNamed('/qr_generator');
                      },
                    ),
                    _ActionButton(
                      icon: Icons.bluetooth_searching,
                      label: 'BLE Broadcast',
                      onTap:
                          schoolProvider.selectedSchool != null &&
                              schoolProvider.selectedClass != null &&
                              schoolProvider.selectedSubject != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BleBroadcastPage(),
                                ),
                              );
                            }
                          : null,
                    ),
                    _ActionButton(
                      icon: Icons.insights,
                      label: 'BLE Diagnostics',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BleDiagnosticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (hasCompleteSelection) ...[
                  Text(
                    'Manual Attendance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (studentProvider.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!studentProvider.loading &&
                      filteredStudentsForManual.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No registered students found for this selection.',
                      ),
                    ),
                  if (!studentProvider.loading &&
                      filteredStudentsForManual.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudentsForManual.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudentsForManual[index];
                        final isPresent = _isStudentAlreadyMarked(
                          student.uuid,
                          attendanceProvider,
                        );
                        final isSelected = _selectedManualStudents.contains(
                          student.uuid,
                        );
                        final subtitleParts = <String>[];
                        if ((student.classId ?? '').isNotEmpty) {
                          subtitleParts.add('Class: ${student.classId}');
                        }
                        if ((student.subjectId ?? '').isNotEmpty) {
                          subtitleParts.add('Subject: ${student.subjectId}');
                        }
                        subtitleParts.add('UUID: ${student.uuid}');
                        return Card(
                          child: CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: isPresent ? true : isSelected,
                            title: Text(
                              student.name.isNotEmpty
                                  ? student.name
                                  : student.uuid,
                            ),
                            subtitle: Text(subtitleParts.join(' • ')),
                            secondary: Icon(
                              isPresent || isSelected
                                  ? Icons.check_circle
                                  : Icons.person_outline,
                              color: isPresent || isSelected
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            onChanged: isPresent
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedManualStudents.add(
                                          student.uuid,
                                        );
                                      } else {
                                        _selectedManualStudents.remove(
                                          student.uuid,
                                        );
                                      }
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  if (!studentProvider.loading &&
                      filteredStudentsForManual.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ElevatedButton.icon(
                        icon: _submittingManual
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _submittingManual
                              ? 'Submitting...'
                              : _selectedManualStudents.isEmpty
                              ? 'Select students to submit'
                              : 'Submit Attendance (${_selectedManualStudents.length})',
                        ),
                        onPressed:
                            _submittingManual || _selectedManualStudents.isEmpty
                            ? null
                            : _submitManualAttendance,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
                Text(
                  'Live Attendance List',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredAttendance.length,
                  itemBuilder: (context, i) {
                    final record = filteredAttendance[i];
                    final student = studentProvider.students.firstWhere(
                      (s) => s.uuid == record.studentUUID,
                      orElse: () => Student(uuid: '', name: ''),
                    );
                    return Card(
                      child: ListTile(
                        leading:
                            (student.profilePhotoUrl != null &&
                                student.profilePhotoUrl!.isNotEmpty)
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  student.profilePhotoUrl!,
                                ),
                              )
                            : (record.facePhotoUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        record.facePhotoUrl!,
                                      ),
                                    )
                                  : CircleAvatar(
                                      child: Text(
                                        student.name.isNotEmpty
                                            ? student.name[0]
                                            : record.studentUUID.isNotEmpty
                                            ? record.studentUUID[0]
                                            : '?',
                                      ),
                                    )),
                        title: Text(
                          student.name.isNotEmpty
                              ? student.name
                              : 'Student: ${record.studentUUID}',
                        ),
                        subtitle: Text(
                          [
                            if (student.email != null &&
                                student.email!.isNotEmpty)
                              student.email!,
                            if (student.classId != null &&
                                student.classId!.isNotEmpty)
                              'Class: ${student.classId}',
                          ].join(' | '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              TimeOfDay.fromDateTime(
                                DateTime.fromMillisecondsSinceEpoch(
                                  record.timestamp,
                                ),
                              ).format(context),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: navIndex,
          onTap: (i) {
            setState(() => navIndex = i);
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(context, '/dashboard');
                break;
              case 1:
                // Already on attendance
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/requests');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/reports');
                break;
              case 4:
                Navigator.pushReplacementNamed(context, '/settings');
                break;
            }
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(180, 56),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
    );
  }
}
