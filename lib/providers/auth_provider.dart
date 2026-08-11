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
  bool _isAuthInitializing = true;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get verificationId => _verificationId;
  bool get isLoggedIn => _user != null;
  bool get isAuthInitializing => _isAuthInitializing;

  // Constructor
  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _user = _authService.getCurrentUser();
    _isAuthInitializing = false;
    notifyListeners();

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
        print('✅ OTP SENT - Verification ID: $verificationId'); // Debug log
        notifyListeners();
      },
      onAutoVerified: (PhoneAuthCredential credential) async {
        // This fires when test phone number auto-verifies
        print('✅ AUTO VERIFIED - Signing in...'); // Debug log
        try {
          UserCredential userCredential = await _authService
              .signInWithCredential(credential);
          _user = userCredential.user;
          if (_user != null) {
            _userModel = UserModel(
              uid: _user!.uid,
              phoneNumber: _user!.phoneNumber ?? '',
              createdAt: DateTime.now(),
            );
            // Save to Firestore
            await _authService.createUserInFirestore(_user!);
          }
          _isLoading = false;
          notifyListeners();
          print('✅ AUTO VERIFY SUCCESS - User: ${_user?.phoneNumber}');
        } catch (e) {
          _error = 'Auto-verify failed: $e';
          _isLoading = false;
          notifyListeners();
          print('❌ AUTO VERIFY FAILED: $e');
        }
      },
      onError: (String errorMessage) {
        _error = errorMessage;
        _isLoading = false;
        print('❌ OTP ERROR: $errorMessage'); // Debug log
        notifyListeners();
      },
    );
  }

  // Verify OTP manually
  Future<bool> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      _error = 'No verification code sent. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 VERIFYING OTP: $smsCode with ID: $_verificationId'); // Debug log

    try {
      _userModel = await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      _user = _authService.getCurrentUser();
      _isLoading = false;

      if (_userModel != null) {
        print('✅ OTP VERIFIED - User logged in: ${_user?.phoneNumber}');
      } else {
        print('❌ OTP VERIFICATION RETURNED NULL');
      }

      notifyListeners();
      return _userModel != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      print('❌ OTP VERIFICATION FAILED: $e');
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();

    _user = null;
    _userModel = null;
    _verificationId = null;
    _error = null;
    _isLoading = false;

    print('👋 SIGNED OUT');
    notifyListeners();
  }
}
