import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/fake_call_model.dart';
import '../services/fake_call_service.dart';

class FakeCallProvider extends ChangeNotifier {
  final FakeCallService _fakeCallService = FakeCallService();

  FakeCallModel? _activeCall;
  bool _isCallActive = false;
  bool _isScheduled = false;
  bool _isCallConnected = false;
  int _scheduledDelay = 0;
  Timer? _scheduleTimer;
  String? _error;

  FakeCallModel? get activeCall => _activeCall;
  bool get isCallActive => _isCallActive;
  bool get isScheduled => _isScheduled;
  bool get isCallConnected => _isCallConnected;
  int get scheduledDelay => _scheduledDelay;
  String? get error => _error;

  // Start immediate fake call
  Future<bool> startImmediateCall() async {
    try {
      final settings = await _fakeCallService.getSavedSettings();

      if (settings == null) {
        _error = 'Please set up caller information first';
        notifyListeners();
        return false;
      }

      _activeCall = FakeCallModel(
        callerName: settings.callerName,
        callerNumber: settings.callerNumber,
        callTime: DateTime.now(),
        isImmediate: true,
        callScript: settings.callScript,
      );

      _isCallActive = true;
      _isCallConnected = false;
      notifyListeners();

      // Start vibration pattern
      await _startVibration();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Schedule fake call
  Future<bool> scheduleCall({required int delayInSeconds}) async {
    try {
      final settings = await _fakeCallService.getSavedSettings();

      if (settings == null) {
        _error = 'Please set up caller information first';
        notifyListeners();
        return false;
      }

      _isScheduled = true;
      _scheduledDelay = delayInSeconds;
      notifyListeners();

      // Start countdown for scheduled call
      _scheduleTimer?.cancel();
      _scheduleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_scheduledDelay > 0) {
          _scheduledDelay--;
          notifyListeners();
        } else {
          timer.cancel();
          _triggerScheduledCall(settings);
        }
      });

      return true;
    } catch (e) {
      _error = e.toString();
      _isScheduled = false;
      notifyListeners();
      return false;
    }
  }

  // Trigger scheduled call
  Future<void> _triggerScheduledCall(FakeCallModel settings) async {
    _activeCall = FakeCallModel(
      callerName: settings.callerName,
      callerNumber: settings.callerNumber,
      callTime: DateTime.now(),
      isImmediate: false,
      callScript: settings.callScript,
    );

    _isCallActive = true;
    _isScheduled = false;
    _isCallConnected = false;
    notifyListeners();

    await _startVibration();
  }

  // Start vibration pattern (simulates phone ringing)
  Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Vibrate in pattern: 500ms on, 200ms off, repeat
        await Vibration.vibrate(
          pattern: [500, 200, 500, 200, 500],
          intensities: [255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
      debugPrint('Vibration failed: $e');
    }
  }

  // Stop vibration
  Future<void> stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Stop vibration failed: $e');
    }
  }

  // Answer call
  Future<void> answerCall() async {
    await stopVibration();
    _isCallConnected = true;
    notifyListeners();
  }

  // End call
  Future<void> endCall() async {
    await stopVibration();
    _isCallActive = false;
    _isCallConnected = false;
    _activeCall = null;
    _isScheduled = false;
    _scheduleTimer?.cancel();
    _scheduledDelay = 0;
    notifyListeners();
  }

  // Decline call (same as end)
  Future<void> declineCall() async {
    await endCall();
  }

  // Cancel scheduled call
  void cancelScheduledCall() {
    _scheduleTimer?.cancel();
    _isScheduled = false;
    _scheduledDelay = 0;
    notifyListeners();
  }

  // Save caller settings
  Future<bool> saveCallerSettings({
    required String callerName,
    required String callerNumber,
    String? callScript,
  }) async {
    try {
      await _fakeCallService.saveCallerSettings(
        callerName: callerName,
        callerNumber: callerNumber,
        callScript: callScript,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if settings exist
  Future<bool> hasSettings() async {
    final settings = await _fakeCallService.getSavedSettings();
    return settings != null;
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }
}
