import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../providers/profile_provider.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';

class BleBroadcastPage extends StatefulWidget {
  const BleBroadcastPage({Key? key}) : super(key: key);

  @override
  State<BleBroadcastPage> createState() => _BleBroadcastPageState();
}

class _BleBroadcastPageState extends State<BleBroadcastPage> {
  bool _scanning = false;
  String? _error;
  String? _foundAdminUUID;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startScan() async {
    setState(() { 
      _error = null; 
      _foundAdminUUID = null;
    });
    
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final student = profileProvider.student;
    
    if (student == null || student.uuid.isEmpty) {
      setState(() { _error = 'Student UUID not found. Please register first.'; });
      return;
    }
    
    // Validate UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(student.uuid)) {
      setState(() { _error = 'Invalid UUID format. Please re-register.'; });
      return;
    }
    
    setState(() { _scanning = true; });
    
    try {
      print('[BLE Scan] Starting scan for admin device...');
      final result = await BLEService().scanForAdmin(
        timeout: const Duration(seconds: 30),
        onDeviceFound: (adminUUID) {
          print('[BLE Scan] Found admin: $adminUUID');
          if (mounted) {
            setState(() { _foundAdminUUID = adminUUID; });
          }
        },
      );
      
      if (result != null) {
        final adminUUID = result['adminUUID'];
        
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
        
        setState(() { 
          _foundAdminUUID = adminUUID;
          _scanning = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully via BLE!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() { 
          _error = 'No admin device found. Make sure admin is broadcasting.';
          _scanning = false;
        });
      }
    } catch (e) {
      print('[BLE Scan] Error: $e');
      setState(() { 
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await BLEService().stopScan();
    setState(() { _scanning = false; });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final uuid = profileProvider.student?.uuid ?? 'Unknown';
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Scan for Admin')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Student UUID:', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(uuid, style: const TextStyle(fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(_scanning ? Icons.stop : Icons.bluetooth_searching),
                  label: Text(_scanning ? 'Stop Scan' : 'Scan for Admin'),
                  onPressed: _scanning ? _stopScan : _startScan,
                ),
                const SizedBox(width: 16),
                Text(_scanning ? 'Scanning...' : 'Not scanning',
                    style: TextStyle(color: _scanning ? Colors.blue : Colors.grey)),
              ],
            ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Looking for admin device...'),
                  ],
                ),
              ),
            if (_foundAdminUUID != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Admin Found!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Admin UUID: $_foundAdminUUID', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 32),
            const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('1. Make sure Bluetooth is ON.'),
            const Text('2. Ask the admin to start broadcasting.'),
            const Text('3. Tap "Scan for Admin" to find the admin device.'),
            const Text('4. Your attendance will be marked when admin device is found.'),
          ],
        ),
      ),
    );
  }
}