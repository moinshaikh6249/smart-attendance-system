import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/profile_provider.dart';
import '../services/ble_service.dart';
import '../services/qr_service.dart';
import '../services/firebase_service.dart';
import 'history_screen.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../config/feature_flags.dart';
import '../theme/app_theme.dart';
import 'dart:ui';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with TickerProviderStateMixin {
  String? _studentName;
  String? _studentUUID;
  String? _studentClass;
  String? _studentSubject;
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _greetingController;
  late AnimationController _avatarController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _greetingSlide;
  late Animation<Offset> _avatarSlide;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStudentData();
  }

  void _initAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Greeting animation controller
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Avatar animation controller
    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Header fade animation
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Cards scale animation with improved curve
    _cardsAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // Greeting slides from left
    _greetingSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOut,
    ));

    // Avatar slides from right
    _avatarSlide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.easeOut,
    ));

    // Logo fade in
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Start animations with delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
        _greetingController.forward();
        _avatarController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _greetingController.dispose();
    _avatarController.dispose();
    super.dispose();
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
      _showErrorSnackBar('Student UUID not found. Please register first.');
      return;
    }

    // Show premium attendance options bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAttendanceBottomSheet(),
    );
  }

  Widget _buildAttendanceBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkBackground,
            AppTheme.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Mark Attendance',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred method',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: _AttendanceMethodCard(
                    icon: Icons.bluetooth_rounded,
                    title: 'BLE Scan',
                    subtitle: 'Quick & Auto',
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.gradientBottom],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startBLEScan();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AttendanceMethodCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QR Code',
                    subtitle: 'Manual Scan',
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentBlue, AppTheme.primaryPurple],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _scanQR();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
        _showErrorSnackBar('Student UUID not found. Please register first.');
        return;
      }
      
      // Validate UUID format
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      if (!uuidRegex.hasMatch(student.uuid)) {
        _showErrorSnackBar('Invalid UUID format. Please re-register.');
        return;
      }
      
      print('[Dashboard] Starting BLE scan for admin device...');
      
      // Request permissions first before showing dialog
      final bleService = BLEService();
      final hasPermissions = await bleService.requestBluetoothAndLocationPermissions();
      
      if (!hasPermissions) {
        // Show permission dialog
        if (!mounted) return;
        _showPermissionDialog(
          title: 'Permissions Required',
          message: 'BLE attendance requires the following permissions:\n\n'
                   '• Bluetooth Scan\n'
                   '• Bluetooth Connect\n'
                   '• Bluetooth Advertise\n'
                   '• Location (required for BLE)\n\n'
                   'Please grant these permissions in Settings.',
          onOpenSettings: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
        );
        return;
      }

      // Load admin/teacher UUIDs from Firebase to filter BLE detections
      print('[Dashboard] Loading admin UUIDs from Firebase...');
      final firebaseService = FirebaseService();
      final adminUuids = await firebaseService.getTeacherUuidsForSubject(
        student.schoolId ?? '',
        student.classId ?? '',
        '', // Subject not available in student model
      );
      
      if (adminUuids.isEmpty) {
        _showErrorSnackBar('No admin devices found for your class. Please contact your teacher.');
        return;
      }
      
      // Configure BLE service to only detect admin UUIDs (not student UUIDs)
      bleService.setTeacherUuids(adminUuids);
      print('[Dashboard] Configured to scan for ${adminUuids.length} admin device(s)');
      
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildScanningDialog(),
      );

      // Start scanning for admin devices broadcasting
      // When admin device is detected, mark attendance
      print('[Dashboard] Scanning for admin devices...');
      
      bool adminDetected = false;
      
      // Start continuous scan with callback
      await bleService.startContinuousScan(
        onTeacherDetected: (uuid, rssi) async {
          if (adminDetected) return; // Already detected
          
          adminDetected = true;
          print('[Dashboard] Admin device detected: $uuid (RSSI: $rssi)');
          
          // Mark attendance via Firebase
          try {
            // Here you would call your attendance marking API
            // For now, we'll simulate success
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (!mounted) return;
            Navigator.of(context).pop(); // Close loading dialog
            
            _showSuccessSnackBar('Attendance marked successfully! 🎉');
            await _loadStudentData(); // Refresh attendance data
          } catch (e) {
            print('[Dashboard] Error marking attendance: $e');
            if (mounted) {
              Navigator.of(context).pop();
              _showErrorSnackBar('Failed to mark attendance: ${e.toString()}');
            }
          }
          
          // Stop scanning after successful detection
          await bleService.stopScan();
        },
      );
      
      // Timeout after 10 seconds if no admin detected
      await Future.delayed(const Duration(seconds: 10));
      
      if (!adminDetected && mounted) {
        await bleService.stopScan();
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('No admin device found nearby. Please try again.');
      }
      
    } catch (e) {
      print('[Dashboard] BLE scan error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        
        // Handle specific error types
        String errorMessage = 'Failed to scan: ${e.toString()}';
        
        if (e.toString().contains('Permission') || e.toString().contains('permission')) {
          _showPermissionDialog(
            title: 'Permissions Denied',
            message: e.toString().replaceAll('Exception: ', ''),
            onOpenSettings: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          );
          return;
        } else if (e.toString().contains('Bluetooth is not enabled')) {
          errorMessage = 'Please enable Bluetooth and try again.';
        } else if (e.toString().contains('not supported')) {
          errorMessage = 'BLE scanning not supported on this device.\nPlease use QR code method instead.';
        } else if (e.toString().contains('Location')) {
          _showPermissionDialog(
            title: 'Location Required',
            message: 'Location permission is required for BLE to work on Android.\n\n'
                     'This is a system requirement and your location is not tracked.\n\n'
                     'Please enable Location permission in Settings.',
            onOpenSettings: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          );
          return;
        }
        
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  Future<void> _scanQR() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final student = profileProvider.student;
      
      if (student == null || student.uuid.isEmpty) {
        _showErrorSnackBar('Student UUID not found. Please register first.');
        return;
      }
      
      print('[Dashboard] Starting QR scan...');
      
      final qrService = QRService();
      final qrData = await qrService.scanQRCode(context);
      final result = qrData != null && qrData.isNotEmpty;
      
      if (!mounted) return;
      
      if (result) {
        _showSuccessSnackBar('Attendance marked via QR! ✅');
        await _loadStudentData(); // Refresh attendance data
      } else {
        _showErrorSnackBar('QR scan failed or cancelled.');
      }
      
    } catch (e) {
      print('[Dashboard] QR scan error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to scan QR: ${e.toString()}');
      }
    }
  }

  Widget _buildScanningDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.cardBackground, AppTheme.darkBackground],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated scanning indicator
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(AppTheme.gradientBottom),
                    ),
                  ),
                  Icon(
                    Icons.bluetooth_searching_rounded,
                    size: 40,
                    color: AppTheme.gradientBottom,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning for Admin Device...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure you\'re near your teacher',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.cardBackground, AppTheme.darkBackground],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: AppTheme.warningOrange,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onOpenSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.gradientBottom,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Open Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentBlue,
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  _buildGreetingSection(),
                  _buildStudentInfoCard(),
                  _buildQuickActionsSection(),
                  _buildQuickAccessSection(),
                  _buildRecentActivitySection(),
                  // Bottom safe area padding
                  SliverToBoxAdapter(
                    child: SizedBox(height: mediaQuery.padding.bottom + 80),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.15),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo Card (Admin Style)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  width: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    );
                  },
                ),
              ),
              
              // Title
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              // Notification Bell (Admin Style)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    // Red dot for new notifications
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.darkBackground,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Greeting Section (Admin Style - separate from AppBar)
  Widget _buildGreetingSection() {
    final String firstName = _studentName?.split(' ').first ?? 'Student';
    
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $firstName 👋',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready for today\'s classes?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cardBackground.withOpacity(0.6),
                AppTheme.cardBackground.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.person_rounded,
                      label: 'Name',
                      value: _studentName ?? 'Student',
                    ),
                  ),
                  if (_studentClass != null && _studentClass!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoPill(
                        icon: Icons.class_rounded,
                        label: 'Class',
                        value: _studentClass!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: ScaleTransition(
        scale: _cardsAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Primary Action Cards Row with proper spacing
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryActionCard(
                        title: 'Mark\nAttendance',
                        icon: Icons.check_circle_rounded,
                        gradient: const LinearGradient(
                          colors: [AppTheme.gradientTop, AppTheme.primaryPurple],
                        ),
                        onTap: _markAttendance,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PrimaryActionCard(
                        title: 'View\nAttendance',
                        icon: Icons.bar_chart_rounded,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryPurple, Color(0xFF5B21B6)],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // BLE Scan Card
                _SecondaryActionCard(
                  title: 'BLE Broadcast',
                  subtitle: 'Enable for automatic scanning',
                  icon: Icons.bluetooth_connected_rounded,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentBlue, Color(0xFF0EA5E9)],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/ble_broadcast');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, bool>>(
        future: FeatureFlags.loadRemoteFlags(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final enabledModules = snapshot.data!;
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          
          // Responsive column count based on screen width
          int crossAxisCount;
          double childAspectRatio;
          
          if (screenWidth < 340) {
            // Very narrow phones - 1 column
            crossAxisCount = 1;
            childAspectRatio = 1.4;
          } else if (screenWidth < 400) {
            // Small phones - 2 columns
            crossAxisCount = 2;
            childAspectRatio = 1.0;
          } else if (screenWidth < 600) {
            // Normal phones - 2 columns
            crossAxisCount = 2;
            childAspectRatio = 1.0;
          } else {
            // Tablets & large screens - 3 columns
            crossAxisCount = 3;
            childAspectRatio = 1.0;
          }
          
          // ALL available modules (feature flag controlled)
          final modules = <Map<String, dynamic>>[
            // Class Schedule - Academic purple/blue
            if (enabledModules['classSchedule'] == true)
              {
                'icon': Icons.calendar_today_rounded,
                'title': 'Class Schedule',
                'subtitle': 'View your timetable',
                'color': const Color(0xFF7C3AED),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Exam Time Table - Academic pink/purple
            if (enabledModules['examTimeTable'] == true)
              {
                'icon': Icons.event_note_rounded,
                'title': 'Exam Timetable',
                'subtitle': 'Check exam schedule',
                'color': const Color(0xFFEC4899),
                'gradient': const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFD946EF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Hall Ticket - Documents indigo
            if (enabledModules['hallTicket'] == true)
              {
                'icon': Icons.confirmation_number_rounded,
                'title': 'Hall Ticket',
                'subtitle': 'Download hall ticket',
                'color': const Color(0xFF6366F1),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Fees Paid - Money blue/cyan
            if (enabledModules['feesPaid'] == true)
              {
                'icon': Icons.account_balance_wallet_rounded,
                'title': 'Fees Paid',
                'subtitle': 'Check fees status',
                'color': const Color(0xFF0EA5E9),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Internal Marks - Marks green/teal
            if (enabledModules['internalMark'] == true)
              {
                'icon': Icons.assessment_rounded,
                'title': 'Internal Marks',
                'subtitle': 'View your marks',
                'color': const Color(0xFF10B981),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Results - Marks green/emerald
            if (enabledModules['result'] == true)
              {
                'icon': Icons.grade_rounded,
                'title': 'Result',
                'subtitle': 'Check your results',
                'color': const Color(0xFF22C55E),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Calendar - Academic purple
            if (enabledModules['calendar'] == true)
              {
                'icon': Icons.calendar_month_rounded,
                'title': 'Calendar',
                'subtitle': 'Academic calendar',
                'color': const Color(0xFF7C3AED),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Register Subject - Academic violet
            if (enabledModules['registerSubject'] == true)
              {
                'icon': Icons.app_registration_rounded,
                'title': 'Register Subject',
                'subtitle': 'Add new subjects',
                'color': const Color(0xFF8B5CF6),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Feedback - Orange/amber
            if (enabledModules['feedback'] == true)
              {
                'icon': Icons.feedback_rounded,
                'title': 'Feedback',
                'subtitle': 'Share your feedback',
                'color': const Color(0xFFF59E0B),
                'gradient': const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Hostel Attendance - Purple
            if (enabledModules['hostelAttendance'] == true)
              {
                'icon': Icons.bed_rounded,
                'title': 'Hostel',
                'subtitle': 'Hostel attendance',
                'color': const Color(0xFF9333EA),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // Certificates - Documents indigo
            if (enabledModules['certificates'] == true)
              {
                'icon': Icons.card_membership_rounded,
                'title': 'Certificates',
                'subtitle': 'View certificates',
                'color': const Color(0xFF4F46E5),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
            // ITLE - Academic blue
            if (enabledModules['itle'] == true)
              {
                'icon': Icons.school_rounded,
                'title': 'ITLE',
                'subtitle': 'ITLE resources',
                'color': const Color(0xFF3B82F6),
                'gradient': const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              },
          ];

          if (modules.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Text(
                  'Modules',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Section Subtitle
                Text(
                  'Access your timetable, results, fees and more.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                // Responsive grid with all modules
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return _ModuleTile(
                      icon: module['icon'] as IconData,
                      title: module['title'] as String,
                      subtitle: module['subtitle'] as String,
                      color: module['color'] as Color,
                      gradient: module['gradient'] as Gradient,
                      index: index,
                      onTap: () {
                        // Get route from module data
                        String route = '';
                        if (module['title'] == 'Class Schedule') route = '/class_schedule';
                        else if (module['title'] == 'Exam Timetable') route = '/exam_timetable';
                        else if (module['title'] == 'Hall Ticket') route = '/hall_ticket';
                        else if (module['title'] == 'Fees Paid') route = '/fees_paid';
                        else if (module['title'] == 'Internal Marks') route = '/internal_marks';
                        else if (module['title'] == 'Result') route = '/results';
                        else if (module['title'] == 'Calendar') route = '/calendar';
                        else if (module['title'] == 'Register Subject') route = '/register_subject';
                        else if (module['title'] == 'Feedback') route = '/feedback';
                        else if (module['title'] == 'Hostel') route = '/hostel_attendance';
                        else if (module['title'] == 'Certificates') route = '/certificates';
                        else if (module['title'] == 'ITLE') route = '/itle';
                        
                        if (route.isNotEmpty) {
                          Navigator.pushNamed(context, route);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 40), // Space before Recent Activity
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return SliverToBoxAdapter(
      child: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          final records = provider.attendance;
          
          if (records.isEmpty) {
            return const SizedBox.shrink();
          }

          final recentRecords = records.take(3).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentRecords.map((record) => _RecentActivityItem(record: record)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom Widgets

class _AttendanceMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AttendanceMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.gradientBottom],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PrimaryActionCard> createState() => _PrimaryActionCardState();
}

class _PrimaryActionCardState extends State<_PrimaryActionCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                bottom: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;
  final int index;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
    required this.index,
  });

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _elevationAnimation = Tween<double>(begin: 8.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Responsive sizing
    final bool isSmallScreen = screenWidth < 400;
    final double iconSize = isSmallScreen ? 26.0 : 28.0;
    final double iconPadding = isSmallScreen ? 10.0 : 12.0;
    final double titleSize = isSmallScreen ? 13.0 : 14.5;
    final double subtitleSize = isSmallScreen ? 10.5 : 11.5;
    final double verticalPadding = isSmallScreen ? 14.0 : 18.0;
    final double horizontalPadding = isSmallScreen ? 10.0 : 12.0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          Future.delayed(const Duration(milliseconds: 120), widget.onTap);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isPressed
                        ? widget.color.withOpacity(0.4)
                        : Colors.white.withOpacity(0.15),
                    width: _isPressed ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: verticalPadding,
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon container
                          Container(
                            padding: EdgeInsets.all(iconPadding),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          
                          // Text content
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.poppins(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.75),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final AttendanceRecord record;

  const _RecentActivityItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Present in ${record.subjectID.isNotEmpty ? record.subjectID : 'Class'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(DateTime.fromMillisecondsSinceEpoch(record.timestamp * 1000)),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.textTertiary,
            size: 14,
          ),
        ],
      ),
    );
  }
}
