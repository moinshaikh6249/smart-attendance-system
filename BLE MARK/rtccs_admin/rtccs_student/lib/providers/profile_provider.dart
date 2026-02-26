import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import 'dart:io';

class ProfileProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  Student? _student;
  bool _loading = false;
  String? _error;
  String? _success;

  Student? get student => _student;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get success => _success;

  Future<void> fetchProfile(String uuid) async {
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      _student = await _firebaseService.fetchStudentByUUID(uuid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePhoto(String uuid, File file) async {
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      final photoUrl = await _firebaseService.uploadProfilePhoto(file, uuid);
      // Optionally update the student profile in Firebase with the new photo URL
      // (Assume a method exists in FirebaseService to update student profile)
      _student = _student?.copyWith(profilePhotoUrl: photoUrl);
      _success = 'Profile photo updated!';
    } catch (e) {
      _error = 'Failed to update photo: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update student profile (mobile, alternateEmail, profilePhoto)
  Future<void> updateProfile({
    String? mobile,
    String? alternateEmail,
    File? profilePhotoFile,
  }) async {
    if (_student == null) {
      throw Exception('No student profile loaded');
    }

    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      String? photoUrl;

      // Upload profile photo if provided
      if (profilePhotoFile != null) {
        photoUrl = await _firebaseService.uploadProfilePhoto(
          profilePhotoFile,
          _student!.uuid,
        );
      }

      // Update profile in Firebase
      await _firebaseService.updateStudentProfile(
        uuid: _student!.uuid,
        mobile: mobile,
        alternateEmail: alternateEmail,
        profilePhotoUrl: photoUrl,
      );

      // Update local student object
      _student = _student!.copyWith(
        mobile: mobile,
        alternateEmail: alternateEmail,
        profilePhotoUrl: photoUrl ?? _student!.profilePhotoUrl,
      );

      _success = 'Profile updated successfully!';
    } catch (e) {
      _error = 'Failed to update profile: $e';
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
} 