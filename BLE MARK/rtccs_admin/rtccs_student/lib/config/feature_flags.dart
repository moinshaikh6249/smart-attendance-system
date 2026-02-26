import 'package:firebase_database/firebase_database.dart';

/// Feature flag system for optional student modules
/// Each module can be independently enabled/disabled based on backend availability
class FeatureFlags {
  // Static feature flags (can be overridden by remote config)
  static const bool enableClassSchedule = false;
  static const bool enableHostelAttendance = false;
  static const bool enableITLE = false; // LMS / Online Material
  static const bool enableFeesPaid = false;
  static const bool enableCertificates = false;
  static const bool enableHallTicket = false;
  static const bool enableExamTimeTable = false;
  static const bool enableRegisterSubject = false;
  static const bool enableInternalMark = false;
  static const bool enableResult = false;
  static const bool enableCalendar = false;
  static const bool enableFeedback = false;

  /// Load feature flags from Firebase Remote Config
  /// Falls back to static defaults if remote config is unavailable
  static Future<Map<String, bool>> loadRemoteFlags({String? schoolId}) async {
    try {
      // Try to load from Firebase
      final ref = FirebaseDatabase.instance.ref('app_config/student_features');
      
      // If schoolId is provided, check school-specific config first
      if (schoolId != null && schoolId.isNotEmpty) {
        final schoolSnapshot = await ref.child(schoolId).get();
        if (schoolSnapshot.exists) {
          return _parseFlags(schoolSnapshot.value as Map);
        }
      }
      
      // Fall back to global config
      final globalSnapshot = await ref.child('global').get();
      if (globalSnapshot.exists) {
        return _parseFlags(globalSnapshot.value as Map);
      }
    } catch (e) {
      print('[FeatureFlags] Failed to load remote flags: $e');
    }

    // Return default flags if remote config fails
    return getDefaultFlags();
  }

  /// Get default feature flags
  static Map<String, bool> getDefaultFlags() {
    return {
      'classSchedule': enableClassSchedule,
      'hostelAttendance': enableHostelAttendance,
      'itle': enableITLE,
      'feesPaid': enableFeesPaid,
      'certificates': enableCertificates,
      'hallTicket': enableHallTicket,
      'examTimeTable': enableExamTimeTable,
      'registerSubject': enableRegisterSubject,
      'internalMark': enableInternalMark,
      'result': enableResult,
      'calendar': enableCalendar,
      'feedback': enableFeedback,
    };
  }

  /// Parse flags from Firebase snapshot
  static Map<String, bool> _parseFlags(Map data) {
    final defaults = getDefaultFlags();
    final result = <String, bool>{};

    defaults.forEach((key, defaultValue) {
      result[key] = data[key] == true;
    });

    return result;
  }

  /// Check if a specific feature is enabled
  static Future<bool> isFeatureEnabled(String featureName, {String? schoolId}) async {
    final flags = await loadRemoteFlags(schoolId: schoolId);
    return flags[featureName] ?? false;
  }
}
