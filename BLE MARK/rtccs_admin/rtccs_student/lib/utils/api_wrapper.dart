import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';

/// API configuration for timeout and retry settings
class ApiConfig {
  // Standard timeout for most API calls
  static const Duration standardTimeout = Duration(seconds: 15);
  
  // Shorter timeout for quick operations
  static const Duration quickTimeout = Duration(seconds: 10);
  
  // Longer timeout for file uploads/downloads
  static const Duration fileTimeout = Duration(seconds: 30);
  
  // Maximum retry attempts for failed requests
  static const int maxRetries = 2;
  
  // Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Wrapper for Firebase Database calls with timeout and error handling
class SafeFirebaseCall {
  /// Execute a Firebase Database query with timeout
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    Duration timeout = ApiConfig.standardTimeout,
    String context = 'Firebase operation',
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Request timed out after ${timeout.inSeconds} seconds');
        },
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(context, e, stackTrace);
      rethrow;
    }
  }

  /// Execute Firebase Database query with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    Duration timeout = ApiConfig.standardTimeout,
    int maxRetries = ApiConfig.maxRetries,
    String context = 'Firebase operation',
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Request timed out after ${timeout.inSeconds} seconds');
          },
        );
      } catch (e, stackTrace) {
        attempts++;
        
        if (attempts > maxRetries) {
          ErrorHandler.logError('$context (final attempt)', e, stackTrace);
          rethrow;
        }
        
        ErrorHandler.logError('$context (attempt $attempts)', e, stackTrace);
        
        // Wait before retrying
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    
    throw Exception('Failed after $maxRetries retries');
  }

  /// Get data from Firebase with timeout
  static Future<DataSnapshot> getData({
    required DatabaseReference ref,
    Duration timeout = ApiConfig.standardTimeout,
    String context = 'Get data',
  }) async {
    return await execute(
      operation: () => ref.get(),
      timeout: timeout,
      context: context,
    );
  }

  /// Set data to Firebase with timeout
  static Future<void> setData({
    required DatabaseReference ref,
    required dynamic value,
    Duration timeout = ApiConfig.standardTimeout,
    String context = 'Set data',
  }) async {
    return await execute(
      operation: () => ref.set(value),
      timeout: timeout,
      context: context,
    );
  }

  /// Update data in Firebase with timeout
  static Future<void> updateData({
    required DatabaseReference ref,
    required Map<String, dynamic> value,
    Duration timeout = ApiConfig.standardTimeout,
    String context = 'Update data',
  }) async {
    return await execute(
      operation: () => ref.update(value),
      timeout: timeout,
      context: context,
    );
  }

  /// Push data to Firebase with timeout
  static Future<DatabaseReference> pushData({
    required DatabaseReference ref,
    required dynamic value,
    Duration timeout = ApiConfig.standardTimeout,
    String context = 'Push data',
  }) async {
    return await execute(
      operation: () async {
        final newRef = ref.push();
        await newRef.set(value);
        return newRef;
      },
      timeout: timeout,
      context: context,
    );
  }
}

/// Example usage in existing services:
/// 
/// Before:
/// final snapshot = await FirebaseDatabase.instance.ref('path').get();
/// 
/// After:
/// final snapshot = await SafeFirebaseCall.getData(
///   ref: FirebaseDatabase.instance.ref('path'),
///   context: 'Fetch student attendance',
/// );
/// 
/// With error handling:
/// try {
///   final snapshot = await SafeFirebaseCall.getData(
///     ref: FirebaseDatabase.instance.ref('path'),
///     context: 'Fetch student data',
///   );
///   // Process data
/// } catch (e) {
///   final userMessage = ErrorHandler.getErrorMessage(e);
///   // Show userMessage to user in snackbar/dialog
/// }
