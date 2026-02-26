import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/school_provider.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      settingsProvider.loadSettings();
    });
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBackground,
        title: const Text(
          'Confirm Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (!mounted) return;
      
      // Clear navigation stack and go to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final success = await settingsProvider.clearLocalCache();
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Cached data cleared' : 'Failed to clear cache'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _reloadData() async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
      
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reloading data...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Reload all data from backend
      await Future.wait([
        studentProvider.loadAllStudents(),
        studentProvider.loadPendingApprovals(),
        schoolProvider.loadSchools(),
      ]);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data reloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reloading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showThemeDialog() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBackground,
        title: const Text(
          'Select Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light', ThemeMode.light, settingsProvider),
            _buildThemeOption('Dark', ThemeMode.dark, settingsProvider),
            _buildThemeOption('System Default', ThemeMode.system, settingsProvider),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, ThemeMode mode, SettingsProvider provider) {
    return RadioListTile<ThemeMode>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: mode,
      groupValue: provider.themeMode,
      onChanged: (value) {
        if (value != null) {
          provider.setThemeMode(value);
          Navigator.pop(context);
        }
      },
      activeColor: kPrimaryBlue,
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162235),
      appBar: AppBar(
        backgroundColor: kHeaderNavy,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Settings Section
              _buildSectionHeader('Account Settings'),
              _buildNavigationTile(
                icon: Icons.person,
                title: 'View Profile',
                subtitle: 'Manage your admin profile',
                onTap: () => Navigator.pushNamed(context, '/admin_profile'),
              ),
              const SizedBox(height: 12),
              _buildNavigationTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  Navigator.pushNamed(context, '/admin_profile');
                  // Note: User can change password from profile screen
                },
              ),
              
              const SizedBox(height: 24),
              
              // Theme Preferences Section
              _buildSectionHeader('Theme Preferences'),
              _buildSettingTile(
                icon: Icons.palette,
                title: 'App Theme',
                subtitle: settingsProvider.themeModeDisplayName,
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  onPressed: _showThemeDialog,
                ),
                onTap: _showThemeDialog,
              ),
              
              const SizedBox(height: 24),
              
              // Notification Preferences Section
              _buildSectionHeader('Notification Preferences'),
              _buildSwitchTile(
                icon: Icons.approval,
                title: 'New Student Approval',
                subtitle: 'Notify when students request approval',
                value: settingsProvider.notifyOnNewApproval,
                onChanged: settingsProvider.setNotifyOnNewApproval,
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                icon: Icons.bluetooth,
                title: 'BLE Session Events',
                subtitle: 'Notify on BLE session start/stop',
                value: settingsProvider.notifyOnBLESession,
                onChanged: settingsProvider.setNotifyOnBLESession,
              ),
              const SizedBox(height: 12),
              _buildSwitchTile(
                icon: Icons.summarize,
                title: 'Daily Attendance Summary',
                subtitle: 'Notify when daily summary is ready',
                value: settingsProvider.notifyOnDailySummary,
                onChanged: settingsProvider.setNotifyOnDailySummary,
              ),
              
              const SizedBox(height: 24),
              
              // Data & Storage Section
              _buildSectionHeader('Data & Storage'),
              _buildActionTile(
                icon: Icons.delete_sweep,
                title: 'Clear Local Cache',
                subtitle: 'Clear temporary cached data',
                onTap: _clearCache,
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.refresh,
                title: 'Reload Data',
                subtitle: 'Fetch latest data from server',
                onTap: _reloadData,
              ),
              
              const SizedBox(height: 24),
              
              // Security Settings Section
              _buildSectionHeader('Security Settings'),
              _buildSwitchTile(
                icon: Icons.security,
                title: 'Require PIN on Reopen',
                subtitle: 'Ask for password when app reopens',
                value: settingsProvider.requirePinOnReopen,
                onChanged: settingsProvider.setRequirePinOnReopen,
              ),
              
              const SizedBox(height: 24),
              
              // App Information Section
              _buildSectionHeader('App Information'),
              _buildInfoTile(
                icon: Icons.info,
                title: 'App Name',
                value: 'BLE Mark Admin',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.verified,
                title: 'Version',
                value: '1.0.0',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.calendar_today,
                title: 'Build Date',
                value: 'November 2025',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.business,
                title: 'Powered by',
                value: 'RTCCS Smart Attendance System',
              ),
              
              const SizedBox(height: 24),
              
              // Support & Legal Section
              _buildSectionHeader('Support & Legal'),
              _buildNavigationTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {
                  // Placeholder - replace with actual URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy policy coming soon')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationTile(
                icon: Icons.description,
                title: 'Terms & Conditions',
                subtitle: 'View terms of service',
                onTap: () {
                  // Placeholder - replace with actual URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms & conditions coming soon')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationTile(
                icon: Icons.email,
                title: 'Support / Contact',
                subtitle: 'support@rtccs.edu',
                onTap: () {
                  _launchURL('mailto:support@rtccs.edu');
                },
              ),
              
              const SizedBox(height: 32),
              
              // Logout Button
              _buildLogoutButton(),
              
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [kCardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kPrimaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [kCardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kPrimaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [kCardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kPrimaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [kCardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [kCardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _showLogoutConfirmation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.logout, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}