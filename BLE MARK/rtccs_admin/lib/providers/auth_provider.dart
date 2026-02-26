import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider() {
    _firebaseService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _firebaseService.signIn(email, password);
      // Update last login time
      if (_user != null) {
        await _firebaseService.updateAdminLastLogin(_user!.uid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
    _user = null;
    notifyListeners();
  }
} 