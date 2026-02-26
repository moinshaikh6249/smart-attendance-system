import 'package:flutter/material.dart';
import '../models/admin_profile.dart';
import '../services/firebase_service.dart';
import 'dart:io';

class AdminProfileProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  AdminProfile? _profile;
  bool _loading = false;
  String? _error;

  AdminProfile? get profile => _profile;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Load admin profile from Firebase
  Future<void> loadProfile(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _firebaseService.fetchAdminProfile(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update admin profile (name, mobile, photo)
  Future<bool> updateProfile({
    required String userId,
    required String fullName,
    String? mobileNumber,
    File? profilePhoto,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate name
      if (fullName.trim().isEmpty || fullName.trim().length < 3) {
        _error = 'Full name must be at least 3 characters';
        _loading = false;
        notifyListeners();
        return false;
      }

      // Validate mobile number if provided
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        if (!_isValidMobileNumber(mobileNumber)) {
          _error = 'Invalid mobile number format';
          _loading = false;
          notifyListeners();
          return false;
        }
      }

      String? photoUrl;
      if (profilePhoto != null) {
        photoUrl = await _firebaseService.uploadAdminProfilePhoto(userId, profilePhoto);
      }

      final success = await _firebaseService.updateAdminProfile(
        userId: userId,
        fullName: fullName,
        mobileNumber: mobileNumber,
        profilePhotoUrl: photoUrl,
      );

      if (success) {
        // Reload profile
        await loadProfile(userId);
      } else {
        _error = 'Failed to update profile';
      }

      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change admin password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate new password
      if (newPassword != confirmPassword) {
        _error = 'New password and confirm password do not match';
        _loading = false;
        notifyListeners();
        return false;
      }

      if (!_isValidPassword(newPassword)) {
        _error = 'Password must be at least 8 characters with at least one letter and one number';
        _loading = false;
        notifyListeners();
        return false;
      }

      final success = await _firebaseService.changeAdminPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!success) {
        _error = 'Current password is incorrect';
      }

      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update last login time
  Future<void> updateLastLoginTime(String userId) async {
    try {
      await _firebaseService.updateAdminLastLogin(userId);
    } catch (e) {
      // Silent fail - not critical
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validate mobile number format
  bool _isValidMobileNumber(String mobile) {
    // Remove spaces and dashes
    final cleaned = mobile.replaceAll(RegExp(r'[\s\-]'), '');
    // Check if it's a valid number (10-15 digits)
    return RegExp(r'^[0-9]{10,15}$').hasMatch(cleaned);
  }

  /// Validate password strength
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    // At least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
    // At least one number
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }
}
