import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_sms/flutter_sms.dart' as FlutterSms;
import '../models/contact_model.dart';
import '../models/offline_alert_model.dart';
import '../services/connectivity_service.dart';
import '../services/sms_service.dart';
import '../services/location_service.dart';
// import 'package:flutter_sms/flutter_sms.dart';

class OfflineManagerProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  final SMSService _smsService = SMSService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isOnline = true;
  bool _isInitialized = false;
  List<SmsQueueItem> _smsQueue = [];
  StreamSubscription? _connectivitySubscription;
  String? _error;

  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  bool get isOfflineMode => !_isOnline;
  List<SmsQueueItem> get smsQueue => _smsQueue;
  String? get error => _error;
  int get queueCount => _smsQueue.length;

  // Initialize - MUST be called from main.dart or home screen
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;
    _isInitialized = true;

    // Listen to connectivity changes
    _connectivityService.addListener(() {
      final wasOnline = _isOnline;
      _isOnline = _connectivityService.isOnline;

      if (wasOnline && !_isOnline) {
        debugPrint('🔴 WENT OFFLINE - SMS fallback activated');
      } else if (!wasOnline && _isOnline) {
        debugPrint('🟢 BACK ONLINE - Processing SMS queue');
        _processSmsQueue();
      }

      notifyListeners();
    });

    debugPrint('✅ Offline Manager initialized. Online: $_isOnline');
    notifyListeners();
  }

  // Send offline alert via SMS
  Future<bool> sendOfflineAlert({
    required String type,
    String? customMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'User not logged in';
        notifyListeners();
        return false;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _error = 'Unable to get current location';
        notifyListeners();
        return false;
      }

      // Get contacts
      final contacts = await _getContacts();
      if (contacts.isEmpty) {
        _error = 'No trusted contacts found';
        notifyListeners();
        return false;
      }

      // Compose message
      String message =
          customMessage ??
          _composeDefaultMessage(type, location.latitude, location.longitude);

      debugPrint(
        '📤 Sending offline alert via SMS to ${contacts.length} contacts',
      );

      // Send SMS
      bool success;
      if (_isOnline) {
        // Online - use normal SMS
        success = await _smsService.sendSMSToMultipleNumbers(
          phoneNumbers: contacts.map((c) => c.phoneNumber).toList(),
          message: message,
        );
      } else {
        // Offline - queue for later
        _queueSmsForLater(contacts, message);
        success = true;
        debugPrint('📥 SMS queued (offline mode)');
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Queue SMS for later sending
  void _queueSmsForLater(List<ContactModel> contacts, String message) {
    for (var contact in contacts) {
      final queueItem = SmsQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${contact.phoneNumber}',
        phoneNumber: contact.phoneNumber,
        message: message,
        queuedAt: DateTime.now(),
      );
      _smsQueue.add(queueItem);
    }
    debugPrint('📥 SMS queued: ${_smsQueue.length} messages pending');
    notifyListeners();
  }

  // Process SMS queue when back online
  Future<void> _processSmsQueue() async {
    if (_smsQueue.isEmpty) return;

    debugPrint('📤 Processing SMS queue: ${_smsQueue.length} messages');

    for (var item in _smsQueue) {
      if (!item.sent) {
        try {
          await FlutterSms.sendSMS(
            recipients: [item.phoneNumber],
            message: item.message,
          );
          item.sent = true;
          item.sentAt = DateTime.now();
          debugPrint('✅ SMS sent to ${item.phoneNumber}');
        } catch (e) {
          debugPrint('❌ Failed to send queued SMS: $e');
        }
      }
    }

    _smsQueue.removeWhere((item) => item.sent);
    debugPrint('📤 Remaining queue: ${_smsQueue.length}');
    notifyListeners();
  }

  // Get user's trusted contacts
  Future<List<ContactModel>> _getContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .get();

      return snapshot.docs.map((doc) {
        return ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Failed to get contacts: $e');
      return [];
    }
  }

  // Compose default message
  String _composeDefaultMessage(String type, double lat, double lng) {
    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    switch (type) {
      case 'sos':
        return '''🚨 SAFEWALK SOS 🚨
        
I need immediate help!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent via SMS (offline mode)''';
      case 'checkin_timeout':
        return '''⚠️ SAFEWALK CHECK-IN TIMEOUT ⚠️
        
I didn't check in on time!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent via SMS (offline mode)''';
      case 'route_deviation':
        return '''🛑 SAFEWALK ROUTE DEVIATION 🛑
        
I'm off my expected route!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent via SMS (offline mode)''';
      default:
        return '''⚠️ SAFEWALK ALERT ⚠️
        
📍 Location: $mapsLink
🕐 Time: $timeString

Sent via SMS (offline mode)''';
    }
  }

  // Check connection manually
  Future<bool> checkConnection() async {
    await _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;
    notifyListeners();
    return _isOnline;
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
