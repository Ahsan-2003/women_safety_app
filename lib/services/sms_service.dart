import 'package:flutter_sms/flutter_sms.dart';
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
      final message = composeSOSMessage(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      if (numbers.isEmpty) return false;

      await FlutterSms.sendSMS(recipients: numbers, message: message);

      return true;
    } catch (e) {
      print('SMS failed: $e');
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
      final message = composeCheckinTimeoutMessage(
        latitude: latitude,
        longitude: longitude,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      if (numbers.isEmpty) return false;

      await FlutterSms.sendSMS(recipients: numbers, message: message);

      return true;
    } catch (e) {
      print('SMS failed: $e');
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
      final message = composeRouteDeviationMessage(
        latitude: latitude,
        longitude: longitude,
        deviationDistance: deviationDistance,
      );

      final numbers = contacts.map((c) => c.phoneNumber).toList();

      if (numbers.isEmpty) return false;

      await FlutterSms.sendSMS(recipients: numbers, message: message);

      return true;
    } catch (e) {
      print('SMS failed: $e');
      return false;
    }
  }

  // Send generic alert SMS
  Future<bool> sendGenericAlertSMS({
    required List<ContactModel> contacts,
    required OfflineAlertModel alert,
  }) async {
    try {
      final numbers = contacts.map((c) => c.phoneNumber).toList();

      if (numbers.isEmpty) return false;

      await FlutterSms.sendSMS(recipients: numbers, message: alert.message);

      return true;
    } catch (e) {
      print('SMS failed: $e');
      return false;
    }
  }

  // Compose SOS message
  String composeSOSMessage({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';

    return '''🚨 SAFEWALK EMERGENCY SOS 🚨
    
I NEED IMMEDIATE HELP!

📍 My Location:
${address ?? 'Unknown address'}
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

🕐 Time: ${DateTime.now().toLocal().toString().substring(0, 16)}

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

    return '''⚠️ SAFEWALK CHECK-IN TIMEOUT ⚠️
    
I did not check in on time!

📍 My Last Known Location:
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

🕐 Time: ${DateTime.now().toLocal().toString().substring(0, 16)}

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

    return '''🛑 SAFEWALK ROUTE DEVIATION 🛑
    
I have deviated from my expected route!

📍 Current Location:
Coordinates: $latitude, $longitude
Google Maps: $mapsLink

📏 Deviation: ${deviationDistance.round()} meters off route

🕐 Time: ${DateTime.now().toLocal().toString().substring(0, 16)}

Please check on me!

Sent via SMS (offline mode)''';
  }
}
