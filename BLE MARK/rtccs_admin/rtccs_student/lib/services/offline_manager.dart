import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manager for offline data caching and retrieval
/// Stores last known data for each module to show when offline
class OfflineManager {
  static const String _prefix = 'offline_cache_';
  static const String _timestampSuffix = '_timestamp';

  // Cache keys for different modules
  static const String dashboardKey = '${_prefix}dashboard';
  static const String scheduleKey = '${_prefix}schedule';
  static const String calendarKey = '${_prefix}calendar';
  static const String timetableKey = '${_prefix}timetable';
  static const String feesKey = '${_prefix}fees';
  static const String resultKey = '${_prefix}result';
  static const String internalMarksKey = '${_prefix}internal_marks';
  static const String hallTicketKey = '${_prefix}hall_ticket';
  static const String profileKey = '${_prefix}profile';

  /// Save data to offline cache
  /// [key] - Cache key (use constants above)
  /// [data] - Data to cache (will be JSON encoded)
  static Future<void> saveData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(key, jsonString);
      await prefs.setInt(
        '$key$_timestampSuffix',
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Error saving offline data for $key: $e');
    }
  }

  /// Load data from offline cache
  /// Returns cached data or null if not available
  static Future<dynamic> loadData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
    } catch (e) {
      debugPrint('Error loading offline data for $key: $e');
    }
    return null;
  }

  /// Get cache timestamp for a key
  /// Returns DateTime when data was last cached, or null if not cached
  static Future<DateTime?> getCacheTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('$key$_timestampSuffix');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting cache timestamp for $key: $e');
    }
    return null;
  }

  /// Check if cached data exists for a key
  static Future<bool> hasCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('Error checking cache for $key: $e');
      return false;
    }
  }

  /// Clear cache for a specific key
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('$key$_timestampSuffix');
      debugPrint('Cleared cache for key: $key');
    } catch (e) {
      debugPrint('Error clearing cache for $key: $e');
    }
  }

  /// Clear all offline caches (except authentication data)
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
      debugPrint('Cleared all offline caches');
    } catch (e) {
      debugPrint('Error clearing all caches: $e');
    }
  }

  /// Get formatted cache age string
  /// Example: "Last updated 2 hours ago"
  static Future<String?> getCacheAge(String key) async {
    final timestamp = await getCacheTimestamp(key);
    if (timestamp == null) return null;

    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Last updated just now';
    } else if (difference.inMinutes < 60) {
      return 'Last updated ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return 'Last updated ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Last updated ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}
