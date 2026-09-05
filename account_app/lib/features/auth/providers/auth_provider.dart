import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _userRole = '';
  String _userName = '';
  String _userEmail = '';

  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userEmail => _userEmail;

  Future<bool> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    _isAuthenticated = true;
    _userName = 'Admin User';
    _userEmail = email;
    _userRole = 'Super Admin';
    notifyListeners();
    
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userName = '';
    _userEmail = '';
    _userRole = '';
    notifyListeners();
  }

  Future<bool> loginWithOtp(String phone) async {
    // Simulate OTP send
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _userName = 'Admin User';
    _userEmail = 'admin@chirag.com';
    _userRole = 'Super Admin';
    notifyListeners();
    return true;
  }

  Future<void> resetPassword(String email) async {
    // Simulate password reset
    await Future.delayed(const Duration(seconds: 1));
  }
}
