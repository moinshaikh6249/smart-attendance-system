import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../providers/class_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/profile_provider.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../services/qr_service.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'ble_diagnostics_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _ScanLogEntry {
  const _ScanLogEntry({
    required this.uuid,
    required this.rssi,
    required this.timestamp,
    this.teacherName,
  });

  final String uuid;
  final int rssi;
  final DateTime timestamp;
  final String? teacherName;
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _scanning = false;
  String? _selectedSchoolId;
  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime selectedDate = DateTime.now();
  bool _dropdownLoading = false;
  String? _deviceUUID;
  late BLEService _bleService;
  late FirebaseService _firebaseService;
  final Set<String> _detectedTeacherUuids = {}; // Track detected teachers
  String? _scanError;
  final List<_ScanLogEntry> _scanLog = [];
  bool _markingAttendance = false;

  @override
  void initState() {
    super.initState();
    _bleService = BLEService();
    _firebaseService = FirebaseService();
    _initDeviceBinding();
    _requestPermissions();
    _loadInitialDropdowns();
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  Future<void> _initDeviceBinding() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('student_uuid');

    // Fetch student profile if not loaded
    if (uuid != null && uuid.isNotEmpty && mounted) {
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.student == null) {
        await profileProvider.fetchProfile(uuid);
      }
      final student = profileProvider.student;
      if (student != null) {
        setState(() => _deviceUUID = student.uuid);
        print(
          '[Attendance] Device UUID set from ProfileProvider: ${student.uuid}',
        );
      } else {
        print('[Attendance] No student found in ProfileProvider');
      }
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
    await Permission.camera.request();
  }

  Future<void> _loadInitialDropdowns() async {
    setState(() => _dropdownLoading = true);
    final schoolProvider = context.read<SchoolProvider>();
    await schoolProvider.loadSchools();
    setState(() => _dropdownLoading = false);
  }

  Future<void> _loadTeacherUuids() async {
    if (_selectedSchoolId == null ||
        _selectedClassId == null ||
        _selectedSubjectId == null) {
      return;
    }

    try {
      final uuids = await _firebaseService.getTeacherUuidsForSubject(
        _selectedSchoolId!,
        _selectedClassId!,
        _selectedSubjectId!,
      );
      _bleService.setTeacherUuids(uuids);
      print('[Attendance] Loaded ${uuids.length} teacher UUIDs to scan for');
    } catch (e) {
      print('[Attendance] Error loading teacher UUIDs: $e');
    }
  }

  bool _canStartScan() {
    final profileProvider = context.read<ProfileProvider>();
    final student = profileProvider.student;
    return student != null &&
        _deviceUUID != null &&
        _deviceUUID!.isNotEmpty &&
        _selectedSchoolId != null &&
        _selectedClassId != null &&
        _selectedSubjectId != null;
  }

  Future<void> _startContinuousScan() async {
    if (!_canStartScan()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select school, class, and subject first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Load teacher UUIDs if not already loaded
    await _loadTeacherUuids();

    setState(() {
      _scanning = true;
      _scanError = null;
      _detectedTeacherUuids.clear();
      _scanLog.clear();
    });

    try {
      await _bleService.startContinuousScan(
        onTeacherDetected: (uuid, rssi) {
          // Ignore await to keep scan subscription responsive
          unawaited(_handleTeacherDetected(uuid, rssi));
        },
      );
    } catch (e) {
      print('[Attendance] BLE scan error: $e');
      setState(() {
        _scanning = false;
        _scanError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopScan() async {
    await _bleService.stopScan();
    setState(() {
      _scanning = false;
    });
  }

  void _appendScanLog({
    required String uuid,
    required int rssi,
    String? teacherName,
  }) {
    final entry = _ScanLogEntry(
      uuid: uuid,
      rssi: rssi,
      teacherName: teacherName,
      timestamp: DateTime.now(),
    );
    setState(() {
      _scanLog.insert(0, entry);
      if (_scanLog.length > 20) {
        _scanLog.removeLast();
      }
    });
  }

  Future<void> _handleTeacherDetected(String uuid, int rssi) async {
    if (!_scanning || _detectedTeacherUuids.contains(uuid)) {
      return;
    }

    print('[Attendance] ✓ Teacher detected via BLE: $uuid (RSSI: $rssi)');
    _detectedTeacherUuids.add(uuid);
    try {
      final teacherInfo = await _firebaseService.getTeacherByBleUuid(uuid);
      if (!mounted) return;
      String? teacherName;

      if (teacherInfo != null) {
        teacherName = teacherInfo['name'] as String?;
        await _markAttendanceAutomatically(teacherInfo);
      } else {
        print('[Attendance] Unknown teacher UUID detected: $uuid');
        teacherName = 'Unknown Teacher';
        await _markAttendanceAutomatically({
          'uuid': uuid,
          'name': teacherName,
        });
      }

      _appendScanLog(
        uuid: uuid,
        rssi: rssi,
        teacherName: teacherName,
      );
    } catch (e) {
      print('[Attendance] Error handling teacher detection: $e');
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scanError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to handle detection: $e')),
      );
      await _bleService.stopScan();
    }
  }

  Future<void> _markAttendanceAutomatically(
    Map<String, dynamic> teacherInfo,
  ) async {
    if (_markingAttendance) return;

    final profileProvider = context.read<ProfileProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final student = profileProvider.student;

    if (student == null ||
        _selectedSchoolId == null ||
        _selectedClassId == null ||
        _selectedSubjectId == null) {
      return;
    }

    setState(() {
      _markingAttendance = true;
    });

    final record = AttendanceRecord(
      studentUUID: student.uuid,
      schoolID: _selectedSchoolId!,
      classID: _selectedClassId!,
      subjectID: _selectedSubjectId!,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      method: 'BLE',
      facePhotoUrl: null,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await attendanceProvider.addAttendance(record);
      await _bleService.stopScan();
      if (!mounted) return;
      setState(() {
        _scanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance marked with ${teacherInfo['name'] ?? 'teacher'}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _markingAttendance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final classProvider = context.watch<ClassProvider>();
    final subjectProvider = context.watch<SubjectProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final student = profileProvider.student;

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: _dropdownLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedSchoolId,
                    items: schoolProvider.schools
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) async {
                      setState(() {
                        _selectedSchoolId = val;
                        _selectedClassId = null;
                        _selectedSubjectId = null;
                        _dropdownLoading = true;
                      });
                      if (val != null) await classProvider.loadClasses(val);
                      setState(() => _dropdownLoading = false);
                    },
                    decoration: const InputDecoration(labelText: 'School'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    items: classProvider.classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) async {
                      setState(() {
                        _selectedClassId = val;
                        _selectedSubjectId = null;
                        _dropdownLoading = true;
                      });
                      if (val != null && _selectedSchoolId != null)
                        await subjectProvider.loadSubjects(
                          _selectedSchoolId!,
                          val,
                        );
                      setState(() => _dropdownLoading = false);
                    },
                    decoration: const InputDecoration(labelText: 'Class'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    items: subjectProvider.subjects
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) async {
                      setState(() => _selectedSubjectId = val);
                      if (val != null &&
                          _selectedSchoolId != null &&
                          _selectedClassId != null) {
                        await _loadTeacherUuids();
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 16),
                  if (!_scanning)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bluetooth_searching),
                            label: const Text('Start Scan'),
                            onPressed: _canStartScan()
                                ? _startContinuousScan
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code),
                            label: const Text('QR Fallback'),
                            onPressed: () async {
                              final qr = await QRService().scanQRCode(context);
                              if (qr != null && student != null) {
                                final record = AttendanceRecord(
                                  studentUUID: student.uuid,
                                  schoolID:
                                      _selectedSchoolId ??
                                      student.schoolId ??
                                      '',
                                  classID:
                                      _selectedClassId ?? student.classId ?? '',
                                  subjectID: _selectedSubjectId ?? '',
                                  date: DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now()),
                                  method: 'QR',
                                  facePhotoUrl: null,
                                  timestamp:
                                      DateTime.now().millisecondsSinceEpoch,
                                );
                                await attendanceProvider.addAttendance(record);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Attendance marked successfully via QR Code!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  if (_scanning) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Scan'),
                      onPressed: _stopScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 8),
                    const Text(
                      'Scanning for teachers...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.insights),
                    label: const Text('Open BLE Diagnostics'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BleDiagnosticsScreen(),
                        ),
                      );
                    },
                  ),
                  if (_markingAttendance)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Marking attendance...'),
                        ],
                      ),
                    ),
                  if (_scanLog.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Scan Log',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        itemCount: _scanLog.length,
                        itemBuilder: (context, index) {
                          final entry = _scanLog[index];
                          final timeLabel = DateFormat(
                            'HH:mm:ss',
                          ).format(entry.timestamp);
                          final matched = entry.teacherName != null;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              matched
                                  ? Icons.check_circle
                                  : Icons.device_unknown,
                              color: matched ? Colors.green : Colors.grey,
                            ),
                            title: Text(entry.teacherName ?? 'Unknown device'),
                            subtitle: Text(
                              'UUID: ${entry.uuid}\nRSSI: ${entry.rssi} dBm • $timeLabel',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_scanError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Error: $_scanError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
