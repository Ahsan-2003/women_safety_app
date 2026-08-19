import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_sms/flutter_sms.dart' as FlutterSms;
import '../models/contact_model.dart';
import '../models/offline_alert_model.dart';
import '../services/connectivity_service.dart';
import '../services/sms_service.dart';
import '../services/location_service.dart';

class OfflineManagerProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  final SMSService _smsService = SMSService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isOnline = true;
  bool _isOfflineMode = false;
  final List<SmsQueueItem> _smsQueue = [];
  StreamSubscription? _connectivitySubscription;
  String? _error;

  bool get isOnline => _isOnline;
  bool get isOfflineMode => _isOfflineMode;
  List<SmsQueueItem> get smsQueue => _smsQueue;
  String? get error => _error;

  // Initialize offline manager
  void initialize() {
    _connectivityService.initialize();
    _isOnline = _connectivityService.isOnline;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = _isOnline;
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      if (wasOnline && !_isOnline) {
        _handleWentOffline();
      } else if (!wasOnline && _isOnline) {
        _handleCameOnline();
      }

      notifyListeners();
    });
  }

  // Handle going offline
  void _handleWentOffline() {
    _isOfflineMode = true;
    debugPrint('📴 WENT OFFLINE - SMS fallback activated');
    notifyListeners();
  }

  // Handle coming back online
  void _handleCameOnline() {
    _isOfflineMode = false;
    debugPrint('📶 BACK ONLINE - Resuming normal operations');
    _processSmsQueue();
    notifyListeners();
  }

  // Send offline alert via SMS
  Future<bool> sendOfflineAlert({
    required String type,
    String? customMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

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

      // Create alert model
      final alert = OfflineAlertModel(
        alertId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        type: type,
        latitude: location.latitude,
        longitude: location.longitude,
        address: 'Coordinates: ${location.latitude}, ${location.longitude}',
        timestamp: DateTime.now(),
        message: message,
      );

      // Try to send SMS
      final success = await _smsService.sendGenericAlertSMS(
        contacts: contacts,
        alert: alert,
      );

      if (!success) {
        // Queue for later
        _queueSmsForLater(contacts, message);
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
    debugPrint('${contacts.length} SMS messages queued');
    notifyListeners();
  }

  // Process SMS queue when back online
  Future<void> _processSmsQueue() async {
    if (_smsQueue.isEmpty) return;

    debugPrint('Processing SMS queue: ${_smsQueue.length} messages');

    for (var item in _smsQueue) {
      if (!item.sent) {
        try {
          await FlutterSms.sendSMS(
            recipients: [item.phoneNumber],
            message: item.message,
          );
          item.sent = true;
          item.sentAt = DateTime.now();
          debugPrint('Queued SMS sent to ${item.phoneNumber}');
        } catch (e) {
          debugPrint('Failed to send queued SMS: $e');
        }
      }
    }

    // Remove sent items
    _smsQueue.removeWhere((item) => item.sent);
    debugPrint('Remaining SMS queue: ${_smsQueue.length}');
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

  // Compose default message based on type
  String _composeDefaultMessage(String type, double lat, double lng) {
    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    switch (type) {
      case 'sos':
        return '''🚨 SAFEWALK SOS 🚨
        
I need immediate help!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent offline via SMS''';
      case 'checkin_timeout':
        return '''⚠️ SAFEWALK CHECK-IN TIMEOUT ⚠️
        
I didn't check in on time!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent offline via SMS''';
      case 'route_deviation':
        return '''🛑 SAFEWALK ROUTE DEVIATION 🛑
        
I'm off my expected route!

📍 Location: $mapsLink
🕐 Time: $timeString

Sent offline via SMS''';
      default:
        return '''⚠️ SAFEWALK ALERT ⚠️
        
📍 Location: $mapsLink
🕐 Time: $timeString

Sent offline via SMS''';
    }
  }

  // Check if online
  Future<bool> checkConnection() async {
    _isOnline = await _connectivityService.hasInternetConnection();
    _isOfflineMode = !_isOnline;
    notifyListeners();
    return _isOnline;
  }

  // Clear SMS queue
  void clearSmsQueue() {
    _smsQueue.clear();
    notifyListeners();
  }

  // Get queue count
  int get queueCount => _smsQueue.length;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
