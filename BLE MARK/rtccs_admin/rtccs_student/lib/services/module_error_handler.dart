import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized error handling for optional modules
/// Ensures failures don't affect core attendance functionality
class ModuleErrorHandler {
  /// Handle errors from optional module data loading
  static void handleModuleError(
    BuildContext context,
    String moduleName,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    print('[ModuleError] $moduleName failed: $error');
    
    // Don't show error if context is not mounted
    if (!context.mounted) return;
    
    // Show non-intrusive snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unable to load ${_getModuleDisplayName(moduleName)} right now',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Build error state widget for module screens
  static Widget buildErrorState({
    required String moduleName,
    required String error,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Data',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t load ${_getModuleDisplayName(moduleName)} at this time. Please check your internet connection and try again.',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
                ),
                child: Text(
                  'Error: ${error.length > 100 ? error.substring(0, 100) + "..." : error}',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade300,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget for modules with no data
  static Widget buildEmptyState({
    required String moduleName,
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade300,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No data available for ${_getModuleDisplayName(moduleName)} yet',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state widget
  static Widget buildLoadingState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show timeout error
  static void showTimeoutError(BuildContext context, String moduleName) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(child: Text('Request Timeout')),
          ],
        ),
        content: Text(
          'The server took too long to respond. Please check your internet connection and try again.',
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

  /// Show network error
  static void showNetworkError(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No internet connection. Please check your network.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Wrap async operations with error handling
  static Future<T?> safeExecute<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    required String moduleName,
    VoidCallback? onError,
  }) async {
    try {
      return await operation();
    } on TimeoutException {
      showTimeoutError(context, moduleName);
      onError?.call();
      return null;
    } catch (e) {
      handleModuleError(context, moduleName, e);
      onError?.call();
      return null;
    }
  }

  /// Get user-friendly module name
  static String _getModuleDisplayName(String moduleName) {
    const names = {
      'classSchedule': 'Class Schedule',
      'hostelAttendance': 'Hostel Attendance',
      'itle': 'Learning Materials',
      'feesPaid': 'Fees Information',
      'certificates': 'Certificates',
      'hallTicket': 'Hall Ticket',
      'examTimeTable': 'Exam Timetable',
      'registerSubject': 'Subject Registration',
      'internalMark': 'Internal Marks',
      'result': 'Results',
      'calendar': 'Academic Calendar',
      'feedback': 'Feedback',
    };
    return names[moduleName] ?? moduleName;
  }
}

/// Timeout exception for network requests
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
