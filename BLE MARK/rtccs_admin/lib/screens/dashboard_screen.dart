import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/school_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/attendance_count_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/excel_service.dart';
import '../theme.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int navIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0),
    );
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _chartController.forward();
    });
    
    // Load schools data when dashboard is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      schoolProvider.loadSchools();
      studentProvider.loadAllStudents();
      studentProvider.loadPendingApprovals();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final schoolProvider = context.watch<SchoolProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive breakpoints
    final isSmallDevice = screenWidth < 400;
    final isMediumDevice = screenWidth >= 400 && screenWidth < 500;
    final isLargeDevice = screenWidth >= 500;
    
    // Responsive padding
    final horizontalPadding = 20.0;
    final cardPadding = isLargeDevice ? 24.0 : 20.0;
    
    // Responsive typography scaling
    final largeNumberSize = (screenWidth * 0.12).clamp(40.0, 56.0);
    final titleSize = (screenWidth * 0.048).clamp(18.0, 22.0);
    final cardTitleSize = (screenWidth * 0.045).clamp(16.0, 18.0);
    final bodyTextSize = (screenWidth * 0.036).clamp(13.0, 14.0);

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
                  Text('Exporting attendance...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await ExcelService().exportAttendanceToExcel(
          attendanceProvider.attendance,
          'attendance_export',
          className: schoolProvider.selectedClass?.name,
          subjectName: schoolProvider.selectedSubject?.name,
          studentsList: studentProvider.students,
          adminName: 'Admin', // TODO: Get from auth provider if available
          instituteName: schoolProvider.selectedSchool?.name,
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
          if (result.success) {
            _showExportSuccessBottomSheet(
              context,
              result.fileName!,
              result.filePath!,
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

    return Container(
      decoration: const BoxDecoration(gradient: kPrimaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // CUSTOM HEADER
            _buildCustomHeader(context, titleSize),
            
            // SCROLLABLE CONTENT
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1 - Quick Stats Row
                      _buildQuickStatsRow(
                        attendanceProvider,
                        studentProvider,
                        screenWidth,
                        isSmallDevice,
                        cardPadding,
                        largeNumberSize,
                        cardTitleSize,
                        bodyTextSize,
                      ),
                      const SizedBox(height: 16),
                      
                      // SECTION 2 - Analytics Charts Row
                      _buildAnalyticsChartsRow(
                        screenWidth,
                        isSmallDevice,
                        cardPadding,
                        cardTitleSize,
                        bodyTextSize,
                      ),
                      const SizedBox(height: 24),
                      
                      // SECTION 3 - Actions Panel
                      _buildActionsPanel(
                        handleExport,
                        cardTitleSize,
                        isLargeDevice,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // CUSTOM HEADER
  Widget _buildCustomHeader(BuildContext context, double titleSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kGradientTop, kGradientBottom, kHeaderNavy],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kWhiteText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12), // 12dp spacing
              
              // Title
              Flexible(
                child: Text(
                  'Dashboard',
                  style: TextStyle(
                    color: kWhiteText,
                    fontSize: titleSize.clamp(20.0, 22.0),
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const Spacer(),
              
              // Notification Bell
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kWhiteText.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: kWhiteText, size: 20),
                  onPressed: () {
                    // Future notifications feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications coming soon!')),
                    );
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8), // 8dp spacing
              
              // Admin Avatar - Navigate to Profile
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/admin_profile');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kGradientBottom,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhiteText.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.person, color: kWhiteText, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION 1 - Quick Stats Row
  Widget _buildQuickStatsRow(
    AttendanceProvider attendanceProvider,
    StudentProvider studentProvider,
    double screenWidth,
    bool isSmallDevice,
    double cardPadding,
    double largeNumberSize,
    double cardTitleSize,
    double bodyTextSize,
  ) {
    if (isSmallDevice || screenWidth < 500) {
      return Column(
        children: [
          _buildLiveAttendanceCard(
            attendanceProvider,
            cardPadding,
            largeNumberSize,
            cardTitleSize,
            bodyTextSize,
          ),
          const SizedBox(height: 16),
          _buildStudentInsightsCard(
            studentProvider,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildLiveAttendanceCard(
            attendanceProvider,
            cardPadding,
            largeNumberSize,
            cardTitleSize,
            bodyTextSize,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStudentInsightsCard(
            studentProvider,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveAttendanceCard(
    AttendanceProvider provider,
    double cardPadding,
    double largeNumberSize,
    double cardTitleSize,
    double bodyTextSize,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: kGradientBottom, size: cardTitleSize + 6),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Live Attendance',
                  style: TextStyle(
                    color: kWhiteText,
                    fontSize: cardTitleSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: cardPadding),
          Center(
            child: Text(
              '${provider.attendance.length}',
              style: TextStyle(
                color: kWhiteText,
                fontSize: largeNumberSize,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Students Present',
              style: TextStyle(
                color: kWhiteText.withOpacity(0.8),
                fontSize: bodyTextSize,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInsightsCard(
    StudentProvider studentProvider,
    double cardPadding,
    double cardTitleSize,
    double bodyTextSize,
  ) {
    final totalStudents = studentProvider.students.length;
    final pendingApprovals = studentProvider.pendingApprovals.length;
    final registered = totalStudents - pendingApprovals;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: kChartPink, size: cardTitleSize + 6),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Student Insights',
                  style: TextStyle(
                    color: kWhiteText,
                    fontSize: cardTitleSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: cardPadding),
          _buildInsightRow(
            Icons.group,
            'Total Students',
            totalStudents.toString(),
            bodyTextSize,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.verified_user,
            'Registered',
            registered.toString(),
            bodyTextSize,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            Icons.pending_actions,
            'Pending Approvals',
            pendingApprovals.toString(),
            bodyTextSize,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value, double bodyTextSize) {
    return Row(
      children: [
        Icon(icon, color: kGradientBottom, size: bodyTextSize + 6),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: kWhiteText.withOpacity(0.8),
              fontSize: bodyTextSize,
              height: 1.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: kWhiteText,
            fontSize: bodyTextSize + 2,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // SECTION 2 - Analytics Charts Row
  Widget _buildAnalyticsChartsRow(
    double screenWidth,
    bool isSmallDevice,
    double cardPadding,
    double cardTitleSize,
    double bodyTextSize,
  ) {
    if (isSmallDevice || screenWidth < 600) {
      return Column(
        children: [
          _buildModernChartCard(
            'Subject-wise Attendance',
            [
              _ChartData('Math', 25.0, kChartPurple),
              _ChartData('Science', 35.0, kChartPink),
              _ChartData('English', 40.0, kChartOrange),
            ],
            screenWidth,
            true,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
          const SizedBox(height: 16),
          _buildModernChartCard(
            'Class-wise Attendance',
            [
              _ChartData('Class A', 30.0, kChartPurple),
              _ChartData('Class B', 45.0, kChartPink),
              _ChartData('Class C', 25.0, kChartOrange),
            ],
            screenWidth,
            true,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildModernChartCard(
            'Subject-wise Attendance',
            [
              _ChartData('Math', 25.0, kChartPurple),
              _ChartData('Science', 35.0, kChartPink),
              _ChartData('English', 40.0, kChartOrange),
            ],
            screenWidth,
            false,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernChartCard(
            'Class-wise Attendance',
            [
              _ChartData('Class A', 30.0, kChartPurple),
              _ChartData('Class B', 45.0, kChartPink),
              _ChartData('Class C', 25.0, kChartOrange),
            ],
            screenWidth,
            false,
            cardPadding,
            cardTitleSize,
            bodyTextSize,
          ),
        ),
      ],
    );
  }

  Widget _buildModernChartCard(
    String title,
    List<_ChartData> chartData,
    double screenWidth,
    bool isSmallScreen,
    double cardPadding,
    double cardTitleSize,
    double bodyTextSize,
  ) {
    return _InteractiveChartCard(
      title: title,
      chartData: chartData,
      animation: _chartAnimation,
      screenWidth: screenWidth,
      isSmallScreen: isSmallScreen,
      cardPadding: cardPadding,
      cardTitleSize: cardTitleSize,
      bodyTextSize: bodyTextSize,
    );
  }

  // SECTION 3 - Actions Panel
  Widget _buildActionsPanel(VoidCallback handleExport, double titleSize, bool isLargeDevice) {
    final iconSize = isLargeDevice ? 24.0 : 22.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 12),
          child: Text(
            'Actions',
            style: TextStyle(
              color: kWhiteText,
              fontSize: titleSize.clamp(16.0, 18.0),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _buildActionButton(
          icon: Icons.bluetooth_searching,
          label: 'BLE Broadcast',
          onTap: () => Navigator.of(context).pushNamed('/attendance'),
          delay: 0,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.qr_code_2,
          label: 'Generate QR',
          onTap: () => Navigator.of(context).pushNamed('/qr_generator'),
          delay: 50,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.table_chart,
          label: 'Export to Excel',
          onTap: handleExport,
          delay: 100,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.verified_user,
          label: 'Approve Students',
          onTap: () => Navigator.of(context).pushNamed('/approve'),
          delay: 150,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.search,
          label: 'Student Search',
          onTap: () => Navigator.of(context).pushNamed('/search'),
          delay: 200,
          iconSize: iconSize,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int delay,
    required double iconSize,
  }) {
    return _AnimatedActionButton(
      icon: icon,
      label: label,
      onTap: onTap,
      delay: delay,
      iconSize: iconSize,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: kHeaderNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (i) {
          setState(() => navIndex = i);
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/attendance');
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
        backgroundColor: Colors.transparent,
        selectedItemColor: kGradientBottom,
        unselectedItemColor: kWhiteText.withOpacity(0.7),
        selectedFontSize: 12,
        unselectedFontSize: 0,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: [
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(
              icon: Icons.dashboard,
              isSelected: navIndex == 0,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(
              icon: Icons.people,
              isSelected: navIndex == 1,
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(
              icon: Icons.pending_actions,
              isSelected: navIndex == 2,
            ),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(
              icon: Icons.bar_chart,
              isSelected: navIndex == 3,
            ),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(
              icon: Icons.settings,
              isSelected: navIndex == 4,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showExportSuccessBottomSheet(
    BuildContext context,
    String fileName,
    String filePath,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryBlue.withOpacity(0.95), kPrimaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            
            // Success message
            const Text(
              'Export Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'File saved as',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              'in Downloads',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        if (Platform.isAndroid) {
                          final uri = Uri.parse('content://com.android.externalstorage.documents/document/primary:Download');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        } else {
                          // For iOS, open Files app
                          final file = File(filePath);
                          if (await file.exists()) {
                            await share_plus.Share.shareXFiles([share_plus.XFile(filePath)]);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open file: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.file_open),
                    label: const Text('Open File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        final file = File(filePath);
                        if (await file.exists()) {
                          await share_plus.Share.shareXFiles(
                            [share_plus.XFile(filePath)],
                            text: 'Attendance Export - $fileName',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not share file: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Animated Navigation Icon with scale effect
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;

  const _AnimatedNavIcon({
    required this.icon,
    required this.isSelected,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
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
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.icon,
        size: 24,
      ),
    );
  }
}

// Animated Action Button with scale and shadow effects
class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int delay;
  final double iconSize;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.delay = 0,
    this.iconSize = 22.0,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Scale animation controller for tap effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    
    // Fade-in animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _elevationAnimation = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    // Start fade-in animation with delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _fadeController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  borderRadius: BorderRadius.circular(18),
                  splashColor: kWhiteText.withOpacity(0.2),
                  highlightColor: kWhiteText.withOpacity(0.1),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: _elevationAnimation.value * 2,
                          offset: Offset(0, _elevationAnimation.value / 2),
                        ),
                      ],
                    ),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            widget.icon,
                            color: const Color(0xFFFFFFFF),
                            size: widget.iconSize,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16, // Button label size
                              fontWeight: FontWeight.w600, // Semi-bold
                              height: 1.2, // Button line height
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Chart data model
class _ChartData {
  final String name;
  final double value;
  final Color color;

  _ChartData(this.name, this.value, this.color);
}

// Interactive Chart Card with tap selection
class _InteractiveChartCard extends StatefulWidget {
  final String title;
  final List<_ChartData> chartData;
  final Animation<double> animation;
  final double screenWidth;
  final bool isSmallScreen;
  final double cardPadding;
  final double cardTitleSize;
  final double bodyTextSize;

  const _InteractiveChartCard({
    required this.title,
    required this.chartData,
    required this.animation,
    required this.screenWidth,
    required this.isSmallScreen,
    required this.cardPadding,
    required this.cardTitleSize,
    required this.bodyTextSize,
  });

  @override
  State<_InteractiveChartCard> createState() => _InteractiveChartCardState();
}

class _InteractiveChartCardState extends State<_InteractiveChartCard> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.chartData.fold<double>(0, (sum, item) => sum + item.value);
    
    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: kWhiteText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                // Chart
                Expanded(
                  flex: 3,
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, child) {
                      return PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 55,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                                setState(() {
                                  final index = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                                  _selectedIndex = _selectedIndex == index ? -1 : index;
                                });
                              }
                            },
                          ),
                          sections: List.generate(widget.chartData.length, (index) {
                            final data = widget.chartData[index];
                            final isSelected = _selectedIndex == index;
                            final percentage = (data.value / total * 100);
                            
                            return PieChartSectionData(
                              value: data.value * widget.animation.value,
                              color: data.color,
                              title: '${percentage.toInt()}%',
                              radius: isSelected ? 75 : 65,
                              titleStyle: TextStyle(
                                fontSize: isSelected ? 16 : 13,
                                fontWeight: FontWeight.bold,
                                color: kWhiteText,
                              ),
                              badgeWidget: _selectedIndex == index
                                  ? null
                                  : null,
                            );
                          }),
                          centerSpaceColor: kCardBackground,
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 200),
                        swapAnimationCurve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12), // 12dp chart to legend spacing
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedIndex >= 0) ...[
                        // Selected segment info
                        Container(
                          padding: const EdgeInsets.all(12), // 12dp padding inside
                          decoration: BoxDecoration(
                            color: widget.chartData[_selectedIndex].color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.chartData[_selectedIndex].color.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chartData[_selectedIndex].name,
                                style: const TextStyle(
                                  color: kWhiteText,
                                  fontSize: 14, // Legend size
                                  fontWeight: FontWeight.w500, // Medium
                                  height: 1.4, // Body text line height
                                ),
                              ),
                              const SizedBox(height: 8), // 8dp spacing
                              Text(
                                '${(widget.chartData[_selectedIndex].value / total * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: widget.chartData[_selectedIndex].color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2, // Title line height
                                ),
                              ),
                              const SizedBox(height: 8), // 8dp spacing
                              Text(
                                '${widget.chartData[_selectedIndex].value.toInt()} present',
                                style: TextStyle(
                                  color: kWhiteText.withOpacity(0.8), // White 80%
                                  fontSize: 12,
                                  height: 1.4, // Body text line height
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12), // 12dp spacing
                      ],
                      // Legend items
                      ...List.generate(widget.chartData.length, (index) {
                        final data = widget.chartData[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8), // 8dp between legend items
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: data.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: data.color.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8), // 8dp spacing
                              Expanded(
                                child: Text(
                                  data.name,
                                  style: const TextStyle(
                                    color: kWhiteText,
                                    fontSize: 14, // Legend size
                                    fontWeight: FontWeight.w500, // Medium
                                    height: 1.4, // Body text line height
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
