// import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_sms/flutter_sms.dart' as FlutterSms;
import '../models/contact_model.dart';
import '../models/offline_alert_model.dart';

class SMSService {
  // Send SOS SMS to all contacts
  Future<bool> sendSOSSMSToContacts({
    required List<ContactModel> contacts,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      if (contacts.isEmpty) {
        print('No contacts to send SMS to');
        return false;
      }

      final message = composeSOSMessage(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      // Send SMS to all contacts
      final result = await FlutterSms.sendSMS(
        recipients: numbers,
        message: message,
      );

      print('SMS sent successfully: $result');
      return true;
    } catch (e) {
      print('SMS sending failed: $e');
      return false;
    }
  }

  // Send check-in timeout SMS
  Future<bool> sendCheckinTimeoutSMS({
    required List<ContactModel> contacts,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (contacts.isEmpty) {
        print('No contacts to send SMS to');
        return false;
      }

      final message = composeCheckinTimeoutMessage(
        latitude: latitude,
        longitude: longitude,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      await FlutterSms.sendSMS(recipients: numbers, message: message);

      print('Check-in timeout SMS sent');
      return true;
    } catch (e) {
      print('Check-in timeout SMS failed: $e');
      return false;
    }
  }

  // Send route deviation SMS
  Future<bool> sendRouteDeviationSMS({
    required List<ContactModel> contacts,
    required double latitude,
    required double longitude,
    required double deviationDistance,
  }) async {
    try {
      if (contacts.isEmpty) {
        print('No contacts to send SMS to');
        return false;
      }

      final message = composeRouteDeviationMessage(
        latitude: latitude,
        longitude: longitude,
        deviationDistance: deviationDistance,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      await FlutterSms.sendSMS(recipients: numbers, message: message);

      print('Route deviation SMS sent');
      return true;
    } catch (e) {
      print('Route deviation SMS failed: $e');
      return false;
    }
  }

  // Send generic alert SMS (for offline alerts)
  Future<bool> sendGenericAlertSMS({
    required List<ContactModel> contacts,
    required OfflineAlertModel alert,
  }) async {
    try {
      if (contacts.isEmpty) {
        print('No contacts to send SMS to');
        return false;
      }

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      await FlutterSms.sendSMS(recipients: numbers, message: alert.message);

      print('Generic alert SMS sent');
      return true;
    } catch (e) {
      print('Generic alert SMS failed: $e');
      return false;
    }
  }

  // Send SMS to single contact
  Future<bool> sendSMSToSingleContact({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      await FlutterSms.sendSMS(recipients: [phoneNumber], message: message);

      print('SMS sent to $phoneNumber');
      return true;
    } catch (e) {
      print('SMS to $phoneNumber failed: $e');
      return false;
    }
  }

  // Send SMS to multiple numbers
  Future<bool> sendSMSToMultipleNumbers({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        print('No phone numbers provided');
        return false;
      }

      await FlutterSms.sendSMS(recipients: phoneNumbers, message: message);

      print('SMS sent to ${phoneNumbers.length} contacts');
      return true;
    } catch (e) {
      print('SMS to multiple numbers failed: $e');
      return false;
    }
  }

  // Queue SMS for later (when offline)
  Future<bool> queueSmsForLater({
    required List<ContactModel> contacts,
    required String message,
  }) async {
    // This will be implemented with local storage
    // For now, just return true to indicate queued
    print('SMS queued for ${contacts.length} contacts');
    return true;
  }

  // Process queued SMS messages
  Future<void> processQueuedSms(List<SmsQueueItem> queue) async {
    for (var item in queue) {
      if (!item.sent) {
        final success = await sendSMSToSingleContact(
          phoneNumber: item.phoneNumber,
          message: item.message,
        );

        if (success) {
          item.sent = true;
          item.sentAt = DateTime.now();
          print('Queued SMS sent to ${item.phoneNumber}');
        }
      }
    }
  }

  // Compose SOS message
  String composeSOSMessage({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    return '''🚨 SAFEWALK EMERGENCY SOS 🚨
    
I NEED IMMEDIATE HELP!

📍 My Location:
${address ?? 'Unknown address'}
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

🕐 Time: $timeString

This is an automated emergency alert from SafeWalk.
Please contact me or emergency services immediately!

Sent via SMS (offline mode)''';
  }

  // Compose check-in timeout message
  String composeCheckinTimeoutMessage({
    required double latitude,
    required double longitude,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    return '''⚠️ SAFEWALK CHECK-IN TIMEOUT ⚠️
    
I did not check in on time!

📍 My Last Known Location:
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

🕐 Time: $timeString

Please check on me immediately!

Sent via SMS (offline mode)''';
  }

  // Compose route deviation message
  String composeRouteDeviationMessage({
    required double latitude,
    required double longitude,
    required double deviationDistance,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    return '''🛑 SAFEWALK ROUTE DEVIATION 🛑
    
I have deviated from my expected route!

📍 Current Location:
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

📏 Deviation: ${deviationDistance.round()} meters off route

🕐 Time: $timeString

Please check on me!

Sent via SMS (offline mode)''';
  }

  // Compose generic alert message
  String composeGenericAlertMessage({
    required String alertType,
    required double latitude,
    required double longitude,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    return '''⚠️ SAFEWALK ALERT ⚠️
    
Alert Type: $alertType

📍 Location:
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

🕐 Time: $timeString

Please check on me!

Sent via SMS (offline mode)''';
  }

  // Compose custom message
  String composeCustomMessage({
    required String message,
    required double latitude,
    required double longitude,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final timeString = DateTime.now().toLocal().toString().substring(0, 16);

    return '''$message

📍 Location: $mapsLink
🕐 Time: $timeString

Sent via SafeWalk (offline mode)''';
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // Simple validation - remove non-digits and check length
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  // Format phone number (add country code if missing)
  String formatPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (!digits.startsWith('+')) {
      // Assume local number - add default country code
      return '+$digits';
    }

    return digits;
  }

  // Get SMS character count
  int getSmsCharacterCount(String message) {
    return message.length;
  }

  // Check if message will be split into multiple SMS
  int getSmsPartCount(String message) {
    final length = message.length;
    if (length <= 160) return 1;
    return (length / 153).ceil(); // 153 chars per part for multi-part SMS
  }
}
