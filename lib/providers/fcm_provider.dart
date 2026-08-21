import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_service.dart';

class FCMProvider extends ChangeNotifier {
  final FCMService _fcmService = FCMService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _fcmService.initialize();
    _fcmToken = _fcmService.fcmToken;
    _isInitialized = true;

    // Save token to Firestore
    await _saveTokenToFirestore();

    // Subscribe to user topic
    final user = _auth.currentUser;
    if (user != null) {
      await _fcmService.subscribeToUserTopic(user.uid);
    }

    notifyListeners();
  }

  // Save FCM token to user's document
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _fcmToken == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    _fcmToken = _fcmService.fcmToken;
    await _saveTokenToFirestore();
    notifyListeners();
  }
}
