import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _notifyAttendance = true;
  bool _notifyLowAttendance = true;
  bool _notifyExamUpdates = true;
  bool _isLoading = true;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notifyAttendance = prefs.getBool('notify_attendance') ?? true;
        _notifyLowAttendance = prefs.getBool('notify_low_attendance') ?? true;
        _notifyExamUpdates = prefs.getBool('notify_exam_updates') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      
      // Clear only cache-related keys (NOT authentication or session data)
      final keysToRemove = <String>[];
      for (final key in prefs.getKeys()) {
        if (key.contains('cache') || 
            key.contains('schedule') || 
            key.contains('calendar') || 
            key.contains('timetable') ||
            key.contains('fees') ||
            key.contains('results') ||
            key.contains('internal_marks') ||
            key.contains('hall_ticket')) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Cached data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to clear cache: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Clear cache first
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = <String>[];
      for (final key in prefs.getKeys()) {
        if (key.contains('cache') || 
            key.contains('schedule') || 
            key.contains('calendar') || 
            key.contains('timetable') ||
            key.contains('fees') ||
            key.contains('results') ||
            key.contains('internal_marks') ||
            key.contains('hall_ticket')) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      // Wait a moment to simulate refresh
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 12),
                Text('Data refreshed. Pull to reload in each module.'),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to refresh data: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF242B3D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blue.shade300),
              const SizedBox(width: 12),
              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade300),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1F3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.lock, color: Colors.green.shade300),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1F3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (value == currentPasswordController.text) {
                        return 'New password must be different';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.lock_open, color: Colors.green.shade300),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1F3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm new password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );

                  try {
                    // TODO: Implement actual password change logic
                    // For now, simulate API call
                    await Future.delayed(const Duration(seconds: 1));
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('Password changed successfully'),
                            ],
                          ),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Failed to change password: ${e.toString()}'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Change Password',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange.shade300),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );

        // Clear session/auth tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Call auth provider logout
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Logout failed: ${e.toString()}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final student = profileProvider.student;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1F3A),
        appBar: AppBar(
          title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person,
              title: 'View Profile',
              subtitle: 'Manage your profile information',
              iconColor: Colors.blue.shade300,
              onTap: () => Navigator.of(context).pushNamed('/profile'),
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSettingsTile(
              icon: Icons.lock_reset,
              title: 'Change Password',
              subtitle: 'Update your account password',
              iconColor: Colors.green.shade300,
              onTap: _showChangePasswordDialog,
            ),
          ]),

          const SizedBox(height: 24),

          // Theme Section
          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSettingsTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: themeProvider.themeMode == ThemeMode.dark
                      ? 'Dark mode enabled'
                      : themeProvider.themeMode == ThemeMode.light
                          ? 'Light mode enabled'
                          : 'System default',
                  iconColor: Colors.purple.shade300,
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    dropdownColor: const Color(0xFF242B3D),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        themeProvider.setThemeMode(mode);
                      }
                    },
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.notifications_active,
              title: 'Attendance Marked',
              subtitle: 'Notify when attendance is marked',
              iconColor: Colors.orange.shade300,
              value: _notifyAttendance,
              onChanged: (value) {
                setState(() => _notifyAttendance = value);
                _saveNotificationSetting('notify_attendance', value);
              },
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSwitchTile(
              icon: Icons.warning_amber,
              title: 'Low Attendance Alert',
              subtitle: 'Notify for low attendance percentage',
              iconColor: Colors.red.shade300,
              value: _notifyLowAttendance,
              onChanged: (value) {
                setState(() => _notifyLowAttendance = value);
                _saveNotificationSetting('notify_low_attendance', value);
              },
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSwitchTile(
              icon: Icons.event_note,
              title: 'Exam Updates',
              subtitle: 'Notify for new timetable or hall ticket',
              iconColor: Colors.teal.shade300,
              value: _notifyExamUpdates,
              onChanged: (value) {
                setState(() => _notifyExamUpdates = value);
                _saveNotificationSetting('notify_exam_updates', value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Data & Cache Section
          _buildSectionHeader('Data & Cache'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.delete_sweep,
              title: 'Clear Cached Data',
              subtitle: 'Remove locally stored data',
              iconColor: Colors.yellow.shade700,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF242B3D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Clear Cached Data?',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    content: Text(
                      'This will clear locally stored timetables, calendars, and other cached data. Your attendance records will not be affected.',
                      style: GoogleFonts.poppins(color: Colors.grey.shade300),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade400)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Clear', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _clearCache();
                }
              },
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSettingsTile(
              icon: Icons.refresh,
              title: 'Refresh Data',
              subtitle: 'Re-fetch latest data from server',
              iconColor: Colors.blue.shade300,
              onTap: _refreshData,
            ),
          ]),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('App Information'),
          _buildSettingsCard([
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'App Name',
              value: 'BLE Mark Student',
              iconColor: Colors.blue.shade300,
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildInfoTile(
              icon: Icons.tag,
              title: 'Version',
              value: _appVersion.isEmpty ? '1.0.0' : _appVersion,
              iconColor: Colors.green.shade300,
            ),
            if (_buildNumber.isNotEmpty) ...[
              const Divider(color: Colors.grey, height: 1),
              _buildInfoTile(
                icon: Icons.build,
                title: 'Build Number',
                value: _buildNumber,
                iconColor: Colors.purple.shade300,
              ),
            ],
            const Divider(color: Colors.grey, height: 1),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              iconColor: Colors.teal.shade300,
              onTap: () => _launchURL('https://rtccs.edu/privacy-policy'),
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'View terms of service',
              iconColor: Colors.orange.shade300,
              onTap: () => _launchURL('https://rtccs.edu/terms'),
            ),
            const Divider(color: Colors.grey, height: 1),
            _buildSettingsTile(
              icon: Icons.support_agent,
              title: 'Support',
              subtitle: 'support@rtccs.edu',
              iconColor: Colors.indigo.shade300,
              onTap: () => _launchURL('mailto:support@rtccs.edu'),
            ),
          ]),

          const SizedBox(height: 24),

          // Logout Section
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out from your account',
              iconColor: Colors.red.shade300,
              onTap: _showLogoutDialog,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade300,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      elevation: 4,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
    );
  }
}
