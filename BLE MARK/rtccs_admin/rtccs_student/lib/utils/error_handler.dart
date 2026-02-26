import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized error handler for user-friendly error messages
/// Converts technical errors to human-readable messages
class ErrorHandler {
  /// Convert exception to user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Network errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    // Timeout errors
    if (error is TimeoutException ||
        error.toString().contains('timeout') ||
        error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // HTTP errors
    if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    }
    if (error.toString().contains('404')) {
      return 'Requested data not found.';
    }
    if (error.toString().contains('401') ||
        error.toString().contains('403')) {
      return 'Authentication failed. Please login again.';
    }

    // Firebase errors
    if (error.toString().contains('firebase') ||
        error.toString().contains('FirebaseException')) {
      if (error.toString().contains('permission')) {
        return 'Access denied. Please contact administrator.';
      }
      if (error.toString().contains('network')) {
        return 'Network error. Please check your connection.';
      }
      return 'Unable to connect to server. Please try again.';
    }

    // Parse errors
    if (error.toString().contains('FormatException') ||
        error.toString().contains('parse')) {
      return 'Invalid data received. Please try again.';
    }

    // Generic fallback
    return 'Unable to load data. Please try again later.';
  }

  /// Log error for debugging (silent - not shown to user)
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('=== ERROR in $context ===');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
      debugPrint('========================');
    }
    
    // TODO: Send to remote error tracking (Firebase Crashlytics, Sentry, etc.)
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Get specific error message for attendance operations
  static String getAttendanceErrorMessage(dynamic error) {
    if (error is SocketException || 
        error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Attendance could not be marked due to a network problem.';
    }

    if (error.toString().contains('timeout')) {
      return 'Attendance marking timed out. Please try again.';
    }

    return 'Unable to mark attendance. Please try again.';
  }

  /// Get error message for module loading failures
  static String getModuleErrorMessage(String moduleName, dynamic error) {
    final baseMessage = getErrorMessage(error);
    return 'Unable to load $moduleName. $baseMessage';
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    
    return error is SocketException ||
        error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout');
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error == null) return false;
    
    return error.toString().contains('401') ||
        error.toString().contains('403') ||
        error.toString().contains('unauthorized') ||
        error.toString().contains('authentication');
  }
}

/// Timeout exception for API calls
class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Operation timed out']);

  @override
  String toString() => message;
}
