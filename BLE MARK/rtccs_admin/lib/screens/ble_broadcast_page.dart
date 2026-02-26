import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../providers/school_provider.dart';
import '../providers/auth_provider.dart';
import '../models/teacher.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'ble_diagnostics_screen.dart';
import '../theme.dart';
import '../utils/ui_helpers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class BleBroadcastPage extends StatefulWidget {
  const BleBroadcastPage({Key? key}) : super(key: key);

  @override
  State<BleBroadcastPage> createState() => _BleBroadcastPageState();
}

class _BleBroadcastPageState extends State<BleBroadcastPage> with UIHelpers, SingleTickerProviderStateMixin {
  late BLEService _bleService;
  late FirebaseService _firebaseService;
  late AnimationController _pulseController;
  bool _advertising = false;
  bool _loading = false;
  String? _error;
  String? _teacherUuid;
  Teacher? _teacher;

  @override
  void initState() {
    super.initState();
    _bleService = BLEService();
    _firebaseService = FirebaseService();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _loadTeacherUuid();
    // Check permissions on init but don't block UI
    _checkPermissionsOnInit();
  }

  Future<void> _checkPermissionsOnInit() async {
    // Silently check if permissions are already granted
    try {
      int sdkInt = 0;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        sdkInt = androidInfo.version.sdkInt;
      }

      List<Permission> permissionsToCheck = [];
      if (sdkInt >= 31) {
        permissionsToCheck = [
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.locationWhenInUse,
        ];
      } else {
        permissionsToCheck = [
          Permission.bluetooth,
          Permission.location,
        ];
      }

      // Check current status without requesting
      final statuses = await Future.wait(
        permissionsToCheck.map((p) => p.status),
      );

      final allGranted = statuses.every((status) => status.isGranted);
      if (!allGranted) {
        print('[BleBroadcastPage] Some permissions not granted yet - will request when user starts broadcast');
      }
    } catch (e) {
      print('[BleBroadcastPage] Permission check error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bleService.stopBroadcasting();
    super.dispose();
  }

  Future<void> _loadTeacherUuid() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      setState(() {
        _error = 'Please log in first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get or create teacher record with permanent UUID
      final teacher = await _firebaseService.getOrCreateTeacher(
        user.uid,
        user.email ?? '',
        user.displayName ?? 'Teacher',
      );

      setState(() {
        _teacher = teacher;
        _teacherUuid = teacher.bleUuid;
        _loading = false;
      });

      print('[BleBroadcastPage] Teacher UUID loaded: $_teacherUuid');
    } catch (e) {
      print('[BleBroadcastPage] Error loading teacher UUID: $e');
      setState(() {
        _error = 'Failed to load teacher UUID: $e';
        _loading = false;
      });
    }
  }

  Future<void> _startBroadcast() async {
    final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;

    if (school == null || classroom == null || subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select school, class, and subject first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_teacherUuid == null) {
      await _loadTeacherUuid();
      if (_teacherUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load teacher UUID. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _error = null;
    });

    try {
      // First, request all permissions
      print('[BleBroadcastPage] Requesting permissions...');
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        setState(() {
          _error = 'Bluetooth and Location permissions are required. Please grant all permissions in Settings.';
        });
        return;
      }

      // Prompt user to enable Bluetooth
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Enable Bluetooth'),
            content: const Text(
              'Bluetooth is required to broadcast attendance session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Turn on'),
              ),
            ],
          ),
        );
        if (proceed == true) {
          await FlutterBluePlus.turnOn();
        } else {
          return;
        }
      }

      print(
        '[BleBroadcastPage] Starting broadcast with permanent teacher UUID: $_teacherUuid',
      );
      await _bleService.startBroadcasting(_teacherUuid!);
      setState(() {
        _advertising = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'BLE broadcasting started. Students can now scan for you.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('[BleBroadcastPage] Error: $e');
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      int sdkInt = 0;
      
      // Get Android SDK version
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        sdkInt = androidInfo.version.sdkInt;
        print('[BleBroadcastPage] Android SDK version: $sdkInt');
      }

      Map<Permission, PermissionStatus> statuses = {};

      if (sdkInt >= 31) {
        // Android 12+ (API 31+) - Use new Bluetooth permissions
        print('[BleBroadcastPage] Requesting Android 12+ permissions...');
        statuses = await [
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.locationWhenInUse,
        ].request();
      } else {
        // Android 11 and below - Use legacy Bluetooth permissions
        print('[BleBroadcastPage] Requesting legacy Bluetooth permissions...');
        statuses = await [
          Permission.bluetooth,
          Permission.location,
          Permission.locationWhenInUse,
        ].request();
      }

      print('[BleBroadcastPage] Permission statuses:');
      statuses.forEach((permission, status) {
        print('  $permission: $status');
      });

      bool hasRequiredPermissions = false;

      if (sdkInt >= 31) {
        // For Android 12+, check new permissions
        final bluetoothAdvertise = statuses[Permission.bluetoothAdvertise];
        final location = statuses[Permission.locationWhenInUse];
        
        hasRequiredPermissions = 
          (bluetoothAdvertise?.isGranted ?? false) &&
          (location?.isGranted ?? false);

        if (!hasRequiredPermissions) {
          print('[BleBroadcastPage] Missing Android 12+ permissions');
          print('  Bluetooth Advertise: ${bluetoothAdvertise?.isGranted}');
          print('  Location: ${location?.isGranted}');
        }
      } else {
        // For Android 11 and below, check legacy permissions
        final bluetooth = statuses[Permission.bluetooth];
        final location = statuses[Permission.location] ?? statuses[Permission.locationWhenInUse];
        
        hasRequiredPermissions = 
          (bluetooth?.isGranted ?? false) &&
          (location?.isGranted ?? false);

        if (!hasRequiredPermissions) {
          print('[BleBroadcastPage] Missing legacy permissions');
          print('  Bluetooth: ${bluetooth?.isGranted}');
          print('  Location: ${location?.isGranted}');
        }
      }

      if (!hasRequiredPermissions) {
        // Show informative dialog with option to retry or go to settings
        setState(() {
          _error = sdkInt >= 31
              ? 'Bluetooth Advertise and Location permissions required'
              : 'Bluetooth and Location permissions required';
        });
        
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissions Required'),
            content: Text(
              sdkInt >= 31
                ? 'BLE Broadcast requires:\n'
                  '• Bluetooth Advertise permission\n'
                  '• Location permission\n\n'
                  'These are needed to broadcast your presence to students.\n\n'
                  'Please grant these permissions when prompted, or open Settings to enable them manually.'
                : 'BLE Broadcast requires:\n'
                  '• Bluetooth permission\n'
                  '• Location permission\n\n'
                  'These are needed to broadcast your presence to students.\n\n'
                  'Please grant these permissions when prompted, or open Settings to enable them manually.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('settings'),
                child: const Text('Open Settings'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('retry'),
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
        
        if (action == 'settings') {
          await openAppSettings();
          return false;
        } else if (action == 'retry') {
          // User wants to try again - recursive call
          return await _requestPermissions();
        }
        
        return false;
      }

      print('[BleBroadcastPage] ✓ All required permissions granted');
      return true;
    } catch (e) {
      print('[BleBroadcastPage] Permission request error: $e');
      return false;
    }
  }

  Future<void> _stopBroadcast() async {
    try {
      await _bleService.stopBroadcasting();
      setState(() {
        _advertising = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = Provider.of<SchoolProvider>(context);
    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;

    final canBroadcast = school != null && classroom != null && subject != null;

    return Container(
      decoration: const BoxDecoration(gradient: kPrimaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('BLE Broadcast'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kHeaderNavy, kHeaderNavy.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selection Status Card
              StyledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, color: kGradientBottom, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Selection Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      'School',
                      school?.name ?? 'Not selected',
                      school != null,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      'Class',
                      classroom?.name ?? 'Not selected',
                      classroom != null,
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      'Subject',
                      subject?.name ?? 'Not selected',
                      subject != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Warning if not all selected
              if (!canBroadcast)
                StyledCard(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: kChartOrange, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Please select school, class, and subject in the attendance screen before broadcasting.',
                          style: TextStyle(color: kChartOrange),
                        ),
                      ),
                    ],
                  ),
                ),

              if (canBroadcast) ...[
                // Loading Indicator
                if (_loading) buildLoadingIndicator(message: 'Loading teacher UUID...'),

                // Teacher UUID Card
                if (!_loading && _teacherUuid != null) ...[
                  StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fingerprint, color: kGradientBottom, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Teacher UUID (Permanent)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kWhiteText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            _teacherUuid!,
                            style: TextStyle(
                              fontSize: 12,
                              color: kGradientBottom,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_teacher != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person, color: kWhiteText.withOpacity(0.7), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _teacher!.name,
                                style: TextStyle(
                                  color: kWhiteText.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Broadcast Control Card
                  StyledCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Broadcast Status Indicator
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: _advertising
                                        ? RadialGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.8),
                                              Colors.green.withOpacity(_pulseController.value * 0.3),
                                            ],
                                          )
                                        : RadialGradient(
                                            colors: [
                                              Colors.red.withOpacity(0.5),
                                              Colors.red.withOpacity(0.1),
                                            ],
                                          ),
                                  ),
                                  child: Icon(
                                    _advertising ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                                    color: kWhiteText,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      color: kWhiteText.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _advertising ? 'BROADCASTING' : 'STOPPED',
                                    style: TextStyle(
                                      color: _advertising ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  if (_advertising)
                                    Text(
                                      'Interval: ~100ms',
                                      style: TextStyle(
                                        color: kWhiteText.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        StyledButton(
                          text: _advertising ? 'Stop Broadcast' : 'Start Broadcast',
                          icon: _advertising ? Icons.stop : Icons.play_arrow,
                          onPressed: _advertising ? _stopBroadcast : _startBroadcast,
                        ),
                      ],
                    ),
                  ),

                  // Active Broadcast Info
                  if (_advertising) ...[
                    const SizedBox(height: 20),
                    StyledCard(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Broadcasting in non-connectable mode. Students can detect you via BLE scan.',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],

              // Error Message (only show if user has attempted to broadcast)
              if (_error != null && _error!.isNotEmpty) ...[
                const SizedBox(height: 20),
                StyledCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exception',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Diagnostics Button
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.insights, color: kGradientBottom),
                label: const Text(
                  'Open BLE Diagnostics',
                  style: TextStyle(color: kWhiteText),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kGradientBottom),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BleDiagnosticsScreen(),
                    ),
                  );
                },
              ),

              // Instructions Card
              const SizedBox(height: 24),
              StyledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: kGradientBottom, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstruction('1', 'Make sure school, class, and subject are selected'),
                    _buildInstruction('2', 'Make sure Bluetooth is ON'),
                    _buildInstruction('3', 'Tap Start Broadcast to advertise the attendance session'),
                    _buildInstruction('4', 'Students will scan for this broadcast to mark attendance'),
                    _buildInstruction('5', 'Keep this page open while broadcasting'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isSelected) {
    return Row(
      children: [
        Icon(
          isSelected ? Icons.check_circle : Icons.cancel,
          color: isSelected ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: kWhiteText.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: kWhiteText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kGradientBottom,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: kWhiteText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: kWhiteText.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
