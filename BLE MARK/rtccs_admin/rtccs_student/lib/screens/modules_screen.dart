import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../config/feature_flags.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 100,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Modules',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Access all your academic resources',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modules Grid
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: FutureBuilder<Map<String, bool>>(
                future: FeatureFlags.loadRemoteFlags(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final enabledModules = snapshot.data!;
                  final modules = _buildModulesList(enabledModules);

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _ModuleCard(
                          module: modules[index],
                          index: index,
                          animation: _animationController,
                        );
                      },
                      childCount: modules.length,
                    ),
                  );
                },
              ),
            ),

            // Bottom padding
            SliverToBoxAdapter(
              child: SizedBox(height: mediaQuery.padding.bottom + 100),
            ),
          ],
        ),
      ),
    );
  }

  List<ModuleData> _buildModulesList(Map<String, bool> enabledModules) {
    final modules = <ModuleData>[];

    if (enabledModules['classSchedule'] == true) {
      modules.add(ModuleData(
        icon: Icons.calendar_today_rounded,
        title: 'Class Schedule',
        subtitle: 'View timetable',
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF6A11CB)],
        ),
        route: '/class_schedule',
      ));
    }

    if (enabledModules['examTimeTable'] == true) {
      modules.add(ModuleData(
        icon: Icons.event_note_rounded,
        title: 'Exam Timetable',
        subtitle: 'Exam schedule',
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFD946EF)],
        ),
        route: '/exam_timetable',
      ));
    }

    if (enabledModules['hallTicket'] == true) {
      modules.add(ModuleData(
        icon: Icons.confirmation_number_rounded,
        title: 'Hall Ticket',
        subtitle: 'Download ticket',
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        route: '/hall_ticket',
      ));
    }

    if (enabledModules['feesPaid'] == true) {
      modules.add(ModuleData(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Fees Paid',
        subtitle: 'Payment status',
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
        ),
        route: '/fees_paid',
      ));
    }

    if (enabledModules['internalMark'] == true) {
      modules.add(ModuleData(
        icon: Icons.assessment_rounded,
        title: 'Internal Marks',
        subtitle: 'View marks',
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
        ),
        route: '/internal_marks',
      ));
    }

    if (enabledModules['result'] == true) {
      modules.add(ModuleData(
        icon: Icons.grade_rounded,
        title: 'Result',
        subtitle: 'Check results',
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF10B981)],
        ),
        route: '/results',
      ));
    }

    if (enabledModules['calendar'] == true) {
      modules.add(ModuleData(
        icon: Icons.calendar_month_rounded,
        title: 'Calendar',
        subtitle: 'Academic calendar',
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF5B21B6)],
        ),
        route: '/calendar',
      ));
    }

    if (enabledModules['registerSubject'] == true) {
      modules.add(ModuleData(
        icon: Icons.app_registration_rounded,
        title: 'Register Subject',
        subtitle: 'Add subjects',
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        route: '/register_subject',
      ));
    }

    if (enabledModules['feedback'] == true) {
      modules.add(ModuleData(
        icon: Icons.feedback_rounded,
        title: 'Feedback',
        subtitle: 'Share feedback',
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        ),
        route: '/feedback',
      ));
    }

    return modules;
  }
}

class _ModuleCard extends StatefulWidget {
  final ModuleData module;
  final int index;
  final AnimationController animation;

  const _ModuleCard({
    required this.module,
    required this.index,
    required this.animation,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          Navigator.pushNamed(context, widget.module.route);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.module.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Stack(
              children: [
                // Decorative circle
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
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          widget.module.icon,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.module.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.module.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class ModuleData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final String route;

  ModuleData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.route,
  });
}
