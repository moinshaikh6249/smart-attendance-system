import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _loginLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginActivity();
  }

  Future<void> _loadLoginActivity() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      final logs = await _firebaseService.fetchAdminLoginActivity(authProvider.user!.uid);
      setState(() {
        _loginLogs = logs.reversed.toList(); // Most recent first
        _loading = false;
      });
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
          'Login Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loginLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No login activity found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loginLogs.length,
                  itemBuilder: (context, index) {
                    final log = _loginLogs[index];
                    return _buildLoginLogItem(log);
                  },
                ),
    );
  }

  Widget _buildLoginLogItem(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] as int?;
    final deviceInfo = log['deviceInfo'] as String? ?? 'Unknown Device';
    final ipAddress = log['ipAddress'] as String? ?? 'Unknown IP';
    
    final DateTime? dateTime = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [kCardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Successful Login',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.devices, deviceInfo),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.location_on, ipAddress),
                const SizedBox(height: 4),
                _buildInfoRow(
                  Icons.access_time,
                  dateTime != null ? _formatDateTime(dateTime) : 'Unknown time',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
