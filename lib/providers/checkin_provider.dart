import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/checkin_timer_model.dart';
import '../services/checkin_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class CheckinProvider extends ChangeNotifier {
  final CheckinService _checkinService = CheckinService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  CheckinTimerModel? _activeTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  bool _isLoading = false;
  String? _error;

  CheckinTimerModel? get activeTimer => _activeTimer;
  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTimerActive => _activeTimer != null && _activeTimer!.isActive;

  // Initialize notification service
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  // Start check-in timer
  Future<bool> startCheckinTimer({required int durationMinutes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current location
      final location = await _locationService.getCurrentLocation();

      final timerId = _uuid.v4();
      final now = DateTime.now();
      final expectedEnd = now.add(Duration(minutes: durationMinutes));

      final timer = CheckinTimerModel(
        timerId: timerId,
        userId: user.uid,
        sessionId: 'standalone',
        startTime: now,
        expectedEndTime: expectedEnd,
        lastKnownLatitude: location?.latitude,
        lastKnownLongitude: location?.longitude,
      );

      await _checkinService.createCheckinTimer(timer);
      _activeTimer = timer;
      _remainingSeconds = durationMinutes * 60;
      _elapsedSeconds = 0;

      // Schedule notification for when timer expires
      await _notificationService.scheduleNotification(
        id: 100,
        title: 'SafeWalk Check-in',
        body:
            'Time is up! Are you safe? If you don\'t respond, we\'ll alert your contacts.',
        scheduledTime: expectedEnd,
      );
      // Schedule reminder notifications
      await _scheduleReminderNotifications(durationMinutes);

      // Start countdown
      _startCountdown();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Schedule periodic reminders
  Future<void> _scheduleReminderNotifications(int durationMinutes) async {
    // Schedule reminders at intervals
    final now = DateTime.now();

    // Reminder at halfway point
    // final halfwayMinutes = (durationMinutes / 2).round();
    // if (halfwayMinutes > 0) {
    //   await _notificationService.scheduleNotification(
    //     id: 101,
    //     title: 'SafeWalk Reminder',
    //     body: 'Halfway through your check-in timer. Still safe?',
    //     scheduledTime: now.add(Duration(minutes: halfwayMinutes)),
    //   );
    // }
    // Schedule halfway reminder
    final halfway = now.add(Duration(minutes: (durationMinutes / 2).round()));
    await _notificationService.scheduleNotification(
      id: 101,
      title: 'SafeWalk Reminder',
      body: 'Halfway through your check-in timer. Still safe?',
      scheduledTime: halfway,
    );

    // Reminder 5 minutes before end
    // final fiveMinBefore = durationMinutes - 5;
    // if (fiveMinBefore > 0) {
    //   await _notificationService.scheduleNotification(
    //     id: 102,
    //     title: 'SafeWalk Reminder',
    //     body: '5 minutes left on your check-in timer.',
    //     scheduledTime: now.add(Duration(minutes: fiveMinBefore)),
    //   );
    // }

    // Schedule 5-minute warning
    final fiveMinBefore = const Duration(minutes: 5);
    await _notificationService.scheduleNotification(
      id: 102,
      title: 'SafeWalk Reminder',
      body: '5 minutes left on your check-in timer.',
      scheduledTime: now.add(Duration(minutes: fiveMinBefore.inMinutes)),
    );
  }

  // Start countdown timer
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _elapsedSeconds++;
        notifyListeners();
      } else {
        timer.cancel();
        _handleTimerExpired();
      }
    });
  }

  // Handle timer expiration
  Future<void> _handleTimerExpired() async {
    if (_activeTimer == null) return;

    try {
      // Get last known location
      final location = await _locationService.getCurrentLocation();

      // Send auto-alert
      await _checkinService.sendAutoAlert(
        timerId: _activeTimer!.timerId,
        latitude: location?.latitude ?? _activeTimer!.lastKnownLatitude ?? 0.0,
        longitude:
            location?.longitude ?? _activeTimer!.lastKnownLongitude ?? 0.0,
      );

      // Show immediate notification
      await _notificationService.showNotification(
        id: 200,
        title: 'SAFEWALK ALERT',
        body: 'Check-in timer expired! Alerting your trusted contacts.',
      );

      // Send SMS to contacts
      final message = _composeAutoAlertMessage(
        location?.latitude ?? _activeTimer!.lastKnownLatitude ?? 0.0,
        location?.longitude ?? _activeTimer!.lastKnownLongitude ?? 0.0,
      );

      // Note: SMS sending needs contact list from provider
      // This will be implemented in the full version

      _activeTimer = null;
      _remainingSeconds = 0;
      _elapsedSeconds = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to send alert: $e';
      notifyListeners();
    }
  }

  // Mark user as safe
  Future<void> markSafe() async {
    if (_activeTimer == null) return;

    try {
      await _checkinService.markSafe(_activeTimer!.timerId);

      // Cancel all notifications
      await _notificationService.cancelAllNotifications();

      _countdownTimer?.cancel();
      _activeTimer = null;
      _remainingSeconds = 0;
      _elapsedSeconds = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark safe: $e';
      notifyListeners();
    }
  }

  // Cancel timer
  Future<void> cancelTimer() async {
    _countdownTimer?.cancel();
    await _notificationService.cancelAllNotifications();
    _activeTimer = null;
    _remainingSeconds = 0;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // Compose auto-alert message
  String _composeAutoAlertMessage(double lat, double lng) {
    return '''🚨 SAFEWALK AUTO-ALERT 🚨
    
I didn't check in on time!

📍 Last known location:
Latitude: $lat
Longitude: $lng
Maps: https://maps.google.com/?q=$lat,$lng

Please check on me immediately.
''';
  }

  // Format time
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String get remainingTimeString => formatTime(_remainingSeconds);
  String get elapsedTimeString => formatTime(_elapsedSeconds);

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
