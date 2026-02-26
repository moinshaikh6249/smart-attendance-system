import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/profile_provider.dart';
import '../services/ble_service.dart';
import '../services/qr_service.dart';
import 'history_screen.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../config/feature_flags.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _studentName;
  String? _studentUUID;
  String? _studentClass;
  String? _studentSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('student_uuid');
    
    setState(() {
      _studentName = prefs.getString('student_name') ?? 'Student';
      _studentClass = prefs.getString('student_class') ?? '';
      _studentSubject = prefs.getString('student_subject') ?? '';
    });

    // Fetch the full student profile and attendance from Firebase
    if (uuid != null && uuid.isNotEmpty && mounted) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      
      await Future.wait([
        profileProvider.fetchProfile(uuid),
        attendanceProvider.fetchAttendance(uuid),
      ]);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _markAttendance() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final student = profileProvider.student;
    
    if (student == null || student.uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student UUID not found. Please register first.')),
      );
      return;
    }

    // Show attendance options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark Attendance',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _startBLEScan();
                    },
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('BLE Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _scanQR();
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startBLEScan() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final student = profileProvider.student;
      
      if (student == null || student.uuid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student UUID not found. Please register first.')),
        );
        return;
      }
      
      // Validate UUID format
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (!uuidRegex.hasMatch(student.uuid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid UUID format. Please re-register.')),
        );
        return;
      }
      
      print('[Dashboard] Starting BLE scan for admin device...');
      
      // Show scanning dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Scanning for Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Looking for admin device...'),
              const SizedBox(height: 8),
              Text('Your UUID: ${student.uuid}', 
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                BLEService().stopScan();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      // Scan for admin device
      final result = await BLEService().scanForAdmin(
        timeout: const Duration(seconds: 30),
        onDeviceFound: (adminUUID) {
          print('[Dashboard] Found admin UUID: $adminUUID');
        },
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close scanning dialog
      
      if (result != null) {
        final adminUUID = result['adminUUID'];
        print('[Dashboard] Successfully found admin with UUID: $adminUUID');
        
        // Save attendance record
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final record = AttendanceRecord(
          studentUUID: student.uuid,
          schoolID: student.schoolId ?? '',
          classID: student.classId ?? '',
          subjectID: '',
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          method: 'BLE',
          facePhotoUrl: null,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        
        await attendanceProvider.addAttendance(record);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked successfully!\nMethod: BLE\nAdmin UUID: $adminUUID'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No admin device found. Make sure admin is broadcasting.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('[Dashboard] BLE scan error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BLE scan error: $e')),
        );
      }
    }
  }

  Future<void> _scanQR() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final student = profileProvider.student;
      
      if (student == null || student.uuid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student UUID not found. Please register first.')),
        );
        return;
      }
      
      final qrResult = await QRService().scanQRCode(context);
      if (qrResult != null) {
        // Save attendance record
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final record = AttendanceRecord(
          studentUUID: student.uuid,
          schoolID: student.schoolId ?? '',
          classID: student.classId ?? '',
          subjectID: '',
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          method: 'QR',
          facePhotoUrl: null,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        
        await attendanceProvider.addAttendance(record);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully via QR Code!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR scan error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
          title: const Text('Dashboard'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).pushNamed('/profile');
              },
              tooltip: 'My Profile',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/welcome');
                }
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final student = profileProvider.student;
            return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Info Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                            student?.name ?? _studentName ?? 'Student',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                                                Text(
                            'UUID: ${student?.uuid ?? 'Not available'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoChip(
                            icon: Icons.class_,
                            label: 'Class',
                            value: _studentClass ?? 'N/A',
                          ),
                          _InfoChip(
                            icon: Icons.book,
                            label: 'Subject',
                            value: _studentSubject ?? 'N/A',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: _markAttendance,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.bluetooth,
                                  size: 48,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mark Attendance',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'BLE or QR Code',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'View Attendance',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Daily Records',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // BLE Broadcast Button
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed('/ble_broadcast'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bluetooth_searching,
                            size: 48,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BLE Scan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scan for admin device to mark attendance',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Access to Optional Modules
              FutureBuilder<Map<String, bool>>(
                future: _loadEnabledModules(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final flags = snapshot.data!;
                  final enabledModules = <Map<String, dynamic>>[];
                  
                  // Build list of enabled modules
                  if (flags['classSchedule'] == true) {
                    enabledModules.add({
                      'icon': Icons.calendar_today,
                      'title': 'Schedule',
                      'route': '/class_schedule',
                      'color': Colors.blue,
                    });
                  }
                  if (flags['feesPaid'] == true) {
                    enabledModules.add({
                      'icon': Icons.account_balance_wallet,
                      'title': 'Fees',
                      'route': '/fees_paid',
                      'color': Colors.amber,
                    });
                  }
                  if (flags['result'] == true) {
                    enabledModules.add({
                      'icon': Icons.assessment,
                      'title': 'Results',
                      'route': '/results',
                      'color': Colors.green,
                    });
                  }
                  if (flags['examTimeTable'] == true) {
                    enabledModules.add({
                      'icon': Icons.event_note,
                      'title': 'Exam',
                      'route': '/exam_timetable',
                      'color': Colors.pink,
                    });
                  }
                  
                  // Show grid only if modules are enabled
                  if (enabledModules.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Text(
                          'Quick Access',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: enabledModules.length > 4 ? 4 : enabledModules.length,
                        itemBuilder: (context, index) {
                          final module = enabledModules[index];
                          return _buildQuickAccessTile(
                            icon: module['icon'] as IconData,
                            title: module['title'] as String,
                            color: module['color'] as Color,
                            onTap: () => Navigator.pushNamed(context, module['route'] as String),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // More Services Button
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed('/more'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apps,
                            size: 48,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'More Services',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fees, Results, Schedule, and more',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.purple),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Activity
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<AttendanceProvider>(
                        builder: (context, attendanceProvider, child) {
                          final recentAttendance = attendanceProvider.attendance.take(3).toList();
                          if (recentAttendance.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No recent attendance records',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: recentAttendance.map((record) => ListTile(
                              leading: Icon(
                                record.method == 'BLE' ? Icons.bluetooth : Icons.qr_code,
                                color: record.method == 'BLE' ? Colors.blue : Colors.green,
                              ),
                              title: Text(
                                '${record.subjectID} - ${record.method}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd, yyyy - hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(record.timestamp),
                                ),
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            );
          },
        ),
      ),
    );
  }

  // Load enabled modules from feature flags
  Future<Map<String, bool>> _loadEnabledModules() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;
    return await FeatureFlags.loadRemoteFlags(schoolId: schoolId);
  }

  // Build quick access tile
  Widget _buildQuickAccessTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 