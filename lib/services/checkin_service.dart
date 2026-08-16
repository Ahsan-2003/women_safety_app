import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms/flutter_sms.dart' as FlutterSms;
import '../models/checkin_timer_model.dart';
import '../models/contact_model.dart';

class CheckinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create check-in timer
  Future<String> createCheckinTimer(CheckinTimerModel timer) async {
    try {
      await _firestore
          .collection('checkin_timers')
          .doc(timer.timerId)
          .set(timer.toMap());
      return timer.timerId;
    } catch (e) {
      throw Exception('Failed to create check-in timer: $e');
    }
  }

  // Mark user as safe
  Future<void> markSafe(String timerId) async {
    try {
      await _firestore.collection('checkin_timers').doc(timerId).update({
        'isActive': false,
        'isSafe': true,
        'safeConfirmedTime': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark safe: $e');
    }
  }

  // Send auto-alert when timer expires
  Future<void> sendAutoAlert({
    required String timerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Update timer status
      await _firestore.collection('checkin_timers').doc(timerId).update({
        'isActive': false,
        'isSafe': false,
        'alertSent': true,
        'lastKnownLatitude': latitude,
        'lastKnownLongitude': longitude,
      });

      // Create alert in Firestore
      await _firestore.collection('auto_alerts').add({
        'timerId': timerId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'message':
            'User did not check in on time. Last known location provided.',
      });
    } catch (e) {
      throw Exception('Failed to send auto-alert: $e');
    }
  }

  // Send SMS to all contacts
  Future<void> sendSMSToContacts({required String message}) async {
    try {
      // Get all users (simplified - in real app, get from contacts)
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(_getCurrentUserId())
          .collection('contacts')
          .get();

      List<String> numbers = [];
      for (var doc in contactsSnapshot.docs) {
        final contact = ContactModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        numbers.add(contact.phoneNumber);
      }

      if (numbers.isNotEmpty) {
        await FlutterSms.sendSMS(recipients: numbers, message: message);
      }
    } catch (e) {
      throw Exception('Failed to send SMS: $e');
    }
  }

  // Helper to get current user ID
  String _getCurrentUserId() {
    // This should be passed from provider
    return '';
  }

  // Get active check-in timer for user
  Future<CheckinTimerModel?> getActiveTimer(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('checkin_timers')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return CheckinTimerModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
