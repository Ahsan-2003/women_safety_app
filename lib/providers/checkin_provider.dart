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

  // Initialize
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  // Start check-in timer - SIMPLIFIED, NO NOTIFICATION DEPENDENCY
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

      // Save timer to Firestore
      await _checkinService.createCheckinTimer(timer);

      _activeTimer = timer;
      _remainingSeconds = durationMinutes * 60;
      _elapsedSeconds = 0;

      // Start countdown timer FIRST
      _startCountdown();

      // Try to schedule notifications (won't crash if fails)
      _scheduleNotificationsSafely(durationMinutes, expectedEnd);

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

  // Schedule notifications safely (won't crash app)
  Future<void> _scheduleNotificationsSafely(
    int durationMinutes,
    DateTime expectedEnd,
  ) async {
    try {
      // Only schedule if duration is long enough
      if (durationMinutes > 5) {
        final now = DateTime.now();

        // Halfway reminder
        final halfwayMinutes = (durationMinutes / 2).round();
        if (halfwayMinutes > 0) {
          await _notificationService.scheduleNotification(
            id: 101,
            title: 'SafeWalk Reminder',
            body: 'Halfway through your check-in timer. Still safe?',
            scheduledTime: now.add(Duration(minutes: halfwayMinutes)),
          );
        }

        // 5-minute warning
        if (durationMinutes > 10) {
          await _notificationService.scheduleNotification(
            id: 102,
            title: 'SafeWalk Reminder',
            body: '5 minutes left on your check-in timer.',
            scheduledTime: expectedEnd.subtract(const Duration(minutes: 5)),
          );
        }
      }

      // Final expiration notification
      await _notificationService.scheduleNotification(
        id: 100,
        title: 'SafeWalk Check-in',
        body: 'Time is up! Are you safe?',
        scheduledTime: expectedEnd,
      );
    } catch (e) {
      // Silently fail - countdown still works
      debugPrint('Notification scheduling failed: $e');
    }
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

      // Send auto-alert to Firestore
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
