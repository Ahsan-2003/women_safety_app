// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get verificationId => _verificationId;
  bool get isLoggedIn => _user != null;

  // Constructor
  AuthProvider() {
    _user = _authService.getCurrentUser();
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _userModel = UserModel(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          createdAt: DateTime.now(),
        );
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (String verificationId) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
      },
      onError: (String errorMessage) {
        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Verify OTP
  Future<bool> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      _error = 'No verification code sent. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userModel = await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      _user = _authService.getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return _userModel != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userModel = null;
    _verificationId = null;
    notifyListeners();
  }
}
