import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'attendance_screen.dart';
import 'modules_screen.dart';
import 'reports_screen.dart';
import 'student_settings_screen.dart';
import 'dart:ui';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<AnimationController> _iconAnimationControllers;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      activeColor: AppTheme.primaryPurple,
    ),
    NavItem(
      icon: Icons.history_rounded,
      label: 'Attendance',
      activeColor: AppTheme.accentBlue,
    ),
    NavItem(
      icon: Icons.apps_rounded,
      label: 'Modules',
      activeColor: AppTheme.successGreen,
    ),
    NavItem(
      icon: Icons.analytics_rounded,
      label: 'Reports',
      activeColor: AppTheme.warningOrange,
    ),
    NavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      activeColor: AppTheme.primaryPurple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Create animation controllers for each icon
    _iconAnimationControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    
    // Indicator animation
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _indicatorPosition = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeInOut),
    );
    
    // Animate first icon
    _iconAnimationControllers[0].value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    setState(() {
      // Animate out old icon
      _iconAnimationControllers[_currentIndex].reverse();
      
      // Update index
      final oldIndex = _currentIndex;
      _currentIndex = index;
      
      // Animate in new icon
      _iconAnimationControllers[index].forward();
      
      // Animate indicator
      _indicatorPosition = Tween<double>(
        begin: oldIndex.toDouble(),
        end: index.toDouble(),
      ).animate(
        CurvedAnimation(parent: _indicatorController, curve: Curves.easeInOut),
      );
      _indicatorController.forward(from: 0);
    });
    
    // Change page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          DashboardScreen(),
          AttendanceScreen(),
          ModulesScreen(),
          ReportsScreen(),
          StudentSettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Stack(
              children: [
                // Animated indicator dot
                AnimatedBuilder(
                  animation: _indicatorPosition,
                  builder: (context, child) {
                    final itemWidth = MediaQuery.of(context).size.width / _navItems.length;
                    final position = _indicatorPosition.value * itemWidth + (itemWidth / 2) - 3;
                    
                    return Positioned(
                      bottom: 2,
                      left: position,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _navItems[_currentIndex].activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _navItems[_currentIndex].activeColor.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Nav items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (index) {
                    return _buildNavItem(index);
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _iconAnimationControllers[index],
          builder: (context, child) {
            final scale = isSelected
                ? 0.85 + (_iconAnimationControllers[index].value * 0.3)
                : 1.0;
            final opacity = isSelected ? 1.0 : 0.6;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with glow effect
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: item.activeColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                          : null,
                      child: Icon(
                        item.icon,
                        color: isSelected ? item.activeColor : Colors.white.withOpacity(opacity),
                        size: 26,
                      ),
                    ),
                    
                    // Label (show only when selected)
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.activeColor,
                        ),
                      ),
                    ],
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

class NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
