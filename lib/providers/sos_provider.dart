import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sms/flutter_sms.dart' as FlutterSms;
import 'package:torch_light/torch_light.dart';
import '../models/sos_model.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';

class SOSProvider extends ChangeNotifier {
  final SOSService _sosService = SOSService();
  final LocationService _locationService = LocationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  SOSModel? _activeSOS;
  bool _isLoading = false;
  String? _error;
  bool _isSirenActive = false;
  bool _isFlashlightActive = false;

  SOSModel? get activeSOS => _activeSOS;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSirenActive => _isSirenActive;
  bool get isFlashlightActive => _isFlashlightActive;

  // Trigger SOS
  Future<bool> triggerSOS({String? sessionId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _error = 'Unable to get current location';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get address from coordinates
      final address = await _getAddressFromLocation(
        location.latitude,
        location.longitude,
      );

      // Trigger SOS in Firestore
      final sos = await _sosService.triggerSOS(
        sessionId: sessionId ?? 'standalone',
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
      );

      if (sos != null) {
        _activeSOS = sos;

        // Send SMS to all contacts
        await _sendSMSToContacts(sos);

        // Activate deterrents
        await _activateSiren();
        await _activateFlashlight();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get human-readable address from coordinates
  Future<String> _getAddressFromLocation(double lat, double lng) async {
    try {
      // Simple format if geocoding fails
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}\nGoogle Maps: https://maps.google.com/?q=$lat,$lng';
    } catch (e) {
      return 'Location coordinates available';
    }
  }

  // Send SMS to all trusted contacts
  Future<void> _sendSMSToContacts(SOSModel sos) async {
    try {
      final contacts = await _sosService.getTrustedContacts();

      if (contacts.isEmpty) return;

      final message = _composeSOSMessage(sos);
      final numbers = contacts.map((c) => c.phoneNumber).toList();

      // Send SMS
      await FlutterSms.sendSMS(recipients: numbers, message: message);
    } catch (e) {
      // SMS might fail on emulator - continue with other alerts
      print('SMS failed: $e');
    }
  }

  // Compose SOS message
  String _composeSOSMessage(SOSModel sos) {
    return '''🚨 SAFEWALK EMERGENCY ALERT 🚨
    
I need immediate help!

📍 Location: ${sos.address}

🕐 Time: ${sos.timestamp.toLocal().toString()}

This is an automated emergency alert from SafeWalk. Please contact me or emergency services immediately.
''';
  }

  // Activate siren
  Future<void> _activateSiren() async {
    try {
      _isSirenActive = true;
      notifyListeners();

      // Play alarm sound in loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
    } catch (e) {
      print('Siren failed: $e');
    }
  }

  // Activate flashlight
  Future<void> _activateFlashlight() async {
    try {
      _isFlashlightActive = true;
      notifyListeners();

      await TorchLight.enableTorch();
    } catch (e) {
      print('Flashlight failed: $e');
    }
  }

  // Stop siren
  Future<void> stopSiren() async {
    try {
      await _audioPlayer.stop();
      _isSirenActive = false;
      notifyListeners();
    } catch (e) {
      print('Stop siren failed: $e');
    }
  }

  // Stop flashlight
  Future<void> stopFlashlight() async {
    try {
      await TorchLight.disableTorch();
      _isFlashlightActive = false;
      notifyListeners();
    } catch (e) {
      print('Stop flashlight failed: $e');
    }
  }

  // Cancel SOS (false alarm)
  Future<void> cancelSOS() async {
    if (_activeSOS == null) return;

    try {
      await _sosService.cancelSOS(_activeSOS!.sosId);
      await stopSiren();
      await stopFlashlight();
      _activeSOS = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel SOS: $e';
      notifyListeners();
    }
  }

  // Stop all deterrents
  Future<void> stopAllDeterrents() async {
    await stopSiren();
    await stopFlashlight();
  }
}
