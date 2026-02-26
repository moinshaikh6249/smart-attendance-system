import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/feature_flags.dart';

/// Service to check module availability and handle navigation safely
class ModuleAvailabilityService {
  /// Check if a module is enabled
  static Future<bool> isModuleEnabled(String moduleName, {String? schoolId}) async {
    try {
      return await FeatureFlags.isFeatureEnabled(moduleName, schoolId: schoolId);
    } catch (e) {
      print('[ModuleAvailability] Error checking $moduleName: $e');
      return false;
    }
  }

  /// Navigate to a module with safety check
  static Future<void> navigateToModule({
    required BuildContext context,
    required String moduleName,
    required String route,
    String? schoolId,
  }) async {
    final isEnabled = await isModuleEnabled(moduleName, schoolId: schoolId);

    if (!context.mounted) return;

    if (isEnabled) {
      Navigator.pushNamed(context, route);
    } else {
      _showModuleDisabledDialog(context, moduleName);
    }
  }

  /// Show dialog when module is disabled
  static void _showModuleDisabledDialog(BuildContext context, String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Feature Unavailable')),
          ],
        ),
        content: Text(
          'This feature is currently not available. Please contact your institution administrator.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get all enabled modules for a school
  static Future<Map<String, bool>> getEnabledModules({String? schoolId}) async {
    try {
      return await FeatureFlags.loadRemoteFlags(schoolId: schoolId);
    } catch (e) {
      print('[ModuleAvailability] Error loading flags: $e');
      return FeatureFlags.getDefaultFlags();
    }
  }

  /// Show unavailable screen when user directly navigates to disabled module
  static Widget buildUnavailableScreen(String moduleName) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text(
          moduleName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 100,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 32),
              Text(
                'Feature Not Available',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This feature is currently not enabled for your institution.',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Builder(
                builder: (ctx) => ElevatedButton.icon(
                  onPressed: () {
                    // Go back to previous screen
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wrapper widget to check module availability before showing content
  static Widget moduleGuard({
    required String moduleName,
    required Widget child,
    String? schoolId,
  }) {
    return FutureBuilder<bool>(
      future: isModuleEnabled(moduleName, schoolId: schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1F3A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return buildUnavailableScreen(moduleName);
        }

        return child;
      },
    );
  }
}
