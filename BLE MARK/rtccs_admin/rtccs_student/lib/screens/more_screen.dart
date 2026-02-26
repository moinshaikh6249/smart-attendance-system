import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/feature_flags.dart';
import '../providers/profile_provider.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Map<String, bool> _featureFlags = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatureFlags();
  }

  Future<void> _loadFeatureFlags() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    final flags = await FeatureFlags.loadRemoteFlags(schoolId: schoolId);
    
    if (mounted) {
      setState(() {
        _featureFlags = flags;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('More Services', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadFeatureFlags,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My Profile Section (Always visible)
                  _buildSectionHeader('My Account'),
                  _buildModuleTile(
                    context,
                    icon: Icons.person,
                    title: 'My Profile',
                    subtitle: 'View and edit profile details',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                    ),
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),

                  _buildModuleTile(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences and configuration',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
                    ),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),

                  const SizedBox(height: 24),

                  // Academic Services Section
                  _buildSectionHeader('Academic Services'),
                  if (_featureFlags['classSchedule'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Class Schedule',
                      subtitle: 'View weekly timetable',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/class_schedule'),
                    ),
                  
                  if (_featureFlags['examTimeTable'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.event_note,
                      title: 'Exam Time Table',
                      subtitle: 'View examination schedule',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/exam_timetable'),
                    ),
                  
                  if (_featureFlags['registerSubject'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.app_registration,
                      title: 'Register Subject',
                      subtitle: 'Manage subject registrations',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/register_subject'),
                    ),

                  if (_featureFlags['itle'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.school,
                      title: 'ITLE / LMS',
                      subtitle: 'Online learning materials',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/itle'),
                    ),

                  if (_featureFlags['calendar'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.calendar_month,
                      title: 'Academic Calendar',
                      subtitle: 'Holidays and events',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/calendar'),
                    ),

                  const SizedBox(height: 24),

                  // Examination & Results Section
                  _buildSectionHeader('Examination & Results'),
                  if (_featureFlags['internalMark'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.assignment,
                      title: 'Internal Marks',
                      subtitle: 'View IA marks',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/internal_marks'),
                    ),

                  if (_featureFlags['result'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.assessment,
                      title: 'Results',
                      subtitle: 'View exam results',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/results'),
                    ),

                  if (_featureFlags['hallTicket'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.confirmation_number,
                      title: 'Hall Ticket',
                      subtitle: 'Download admit card',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF673AB7), Color(0xFF9575CD)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/hall_ticket'),
                    ),

                  const SizedBox(height: 24),

                  // Financial Services Section
                  _buildSectionHeader('Financial Services'),
                  if (_featureFlags['feesPaid'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'Fees Payment',
                      subtitle: 'View payment status',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/fees_paid'),
                    ),

                  const SizedBox(height: 24),

                  // Other Services Section
                  _buildSectionHeader('Other Services'),
                  if (_featureFlags['hostelAttendance'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.hotel,
                      title: 'Hostel Attendance',
                      subtitle: 'View hostel records',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/hostel_attendance'),
                    ),

                  if (_featureFlags['certificates'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.card_membership,
                      title: 'Certificates',
                      subtitle: 'Download certificates',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF795548), Color(0xFFA1887F)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/certificates'),
                    ),

                  if (_featureFlags['feedback'] == true)
                    _buildModuleTile(
                      context,
                      icon: Icons.feedback,
                      title: 'Feedback',
                      subtitle: 'Send your feedback',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/feedback'),
                    ),

                  const SizedBox(height: 24),

                  // Always Available
                  _buildSectionHeader('Settings & Support'),
                  _buildModuleTile(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF546E7A), Color(0xFF78909C)],
                    ),
                    onTap: () {
                      // TODO: Navigate to settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon')),
                      );
                    },
                  ),

                  _buildModuleTile(
                    context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'FAQs and contact',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF37474F), Color(0xFF546E7A)],
                    ),
                    onTap: () {
                      // TODO: Navigate to help
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help coming soon')),
                      );
                    },
                  ),

                  // Show message if no modules are enabled
                  if (_featureFlags.values.every((enabled) => !enabled)) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.apps, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'No Additional Services',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Additional services will appear here when enabled by your institution',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
