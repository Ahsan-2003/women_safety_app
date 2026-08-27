import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:women_safety_app/models/session_history_model.dart';
import '../models/session_model.dart';
import '../models/location_model.dart';
import '../services/session_service.dart';
import '../services/location_service.dart';
import '../services/session_history_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  final SessionHistoryService _historyService = SessionHistoryService();

  SessionModel? _activeSession;
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;

  // ADD: Timer and StreamSubscription
  Timer? _timer;
  StreamSubscription? _locationSubscription;
  bool _isTimerRunning = false;
  bool _isLocationTracking = false;

  SessionModel? get activeSession => _activeSession;
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSessionActive =>
      _activeSession != null && _activeSession!.isActive;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerRunning => _isTimerRunning;
  bool get isLocationTracking => _isLocationTracking;

  // Check for existing active session
  Future<void> checkActiveSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _activeSession = await _sessionService.getActiveSession(user.uid);
      if (_activeSession != null) {
        _calculateTimes();
        _startTimer();
        _startLocationTracking(_activeSession!.sessionId);
      }
      notifyListeners();
    } catch (e) {
      // No active session
    }
  }

  // Start a new walk session
  Future<bool> startSession({
    required int durationMinutes,
    String? destinationAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check location permission
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        _error = 'Location permission is required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _error = 'Unable to get current location';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final sessionId = _uuid.v4();
      final now = DateTime.now();

      final shareableLink = _sessionService.generateShareableLink(sessionId);

      final session = SessionModel(
        sessionId: sessionId,
        userId: user.uid,
        startLatitude: location.latitude,
        startLongitude: location.longitude,
        destinationAddress: destinationAddress,
        startTime: now,
        expectedEndTime: now.add(Duration(minutes: durationMinutes)),
        shareableLink: shareableLink,
      );

      await _sessionService.startSession(session);
      _activeSession = session;
      _currentLocation = location;
      _remainingSeconds = durationMinutes * 60;
      _elapsedSeconds = 0;

      // Start location tracking
      _startLocationTracking(sessionId);

      // Start timer
      _startTimer();

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

  // Track location updates
  void _startLocationTracking(String sessionId) {
    _locationSubscription?.cancel();
    _isLocationTracking = true;

    _locationSubscription = _locationService.getLocationStream().listen(
      (location) async {
        _currentLocation = location;
        notifyListeners();

        try {
          await _sessionService.updateLocation(
            sessionId: sessionId,
            location: location,
          );
        } catch (e) {
          // Silently handle - location will update on next interval
        }
      },
      onError: (error) {
        _error = 'Location tracking error: $error';
        _isLocationTracking = false;
        notifyListeners();
      },
    );
  }

  // Start countdown timer
  void _startTimer() {
    _timer?.cancel();
    _isTimerRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isSessionActive) {
        timer.cancel();
        _isTimerRunning = false;
        return;
      }

      _elapsedSeconds++;
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isTimerRunning = false;
        _handleTimerExpired();
      }

      notifyListeners();
    });
  }

  // Handle timer expiration
  Future<void> _handleTimerExpired() async {
    if (_activeSession == null) return;

    try {
      // Get last known location
      final location = await _locationService.getCurrentLocation();

      // End session without safe confirmation
      await _sessionService.endSession(_activeSession!.sessionId);

      // Save to history with alert
      final historyService = SessionHistoryService();
      final historySession = SessionHistoryModel(
        sessionId: _activeSession!.sessionId,
        startTime: _activeSession!.startTime,
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds.toString(),
        startLatitude: _activeSession!.startLatitude,
        startLongitude: _activeSession!.startLongitude,
        destinationAddress: _activeSession!.destinationAddress ?? '',
        completedSafely: false, // NOT safe
        totalDistanceKm: 0,
        alertsTriggered: 1, // Alert was triggered
      );

      await historyService.saveSession(historySession);
      print('⚠️ Session expired - alert triggered');

      _activeSession = null;
      _currentLocation = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to handle timer expiry: $e';
      notifyListeners();
    }
  }

  // End session (safe arrival or timeout)
  Future<void> _endSession({required bool safe}) async {
    if (_activeSession == null) return;

    try {
      await _sessionService.endSession(_activeSession!.sessionId);

      _timer?.cancel();
      _locationSubscription?.cancel();
      _isTimerRunning = false;
      _isLocationTracking = false;

      _activeSession = null;
      _currentLocation = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end session: $e';
      notifyListeners();
    }
  }

  // User marks themselves as safe
  Future<void> markSafe() async {
    if (_activeSession == null) return;

    try {
      await _sessionService.endSession(_activeSession!.sessionId);

      // Save to history
      final historyService = SessionHistoryService();
      final historySession = SessionHistoryModel(
        sessionId: _activeSession!.sessionId,
        startTime: _activeSession!.startTime,
        endTime: DateTime.now(),
        durationMinutes: _elapsedSeconds.toString(),
        startLatitude: _activeSession!.startLatitude,
        startLongitude: _activeSession!.startLongitude,
        destinationAddress: _activeSession!.destinationAddress ?? '',
        completedSafely: true,
        totalDistanceKm: 0,
        alertsTriggered: 0,
      );

      await historyService.saveSession(historySession);
      print('✅ Session saved to history');

      // Clean up
      _timer?.cancel();
      _locationSubscription?.cancel();
      _isTimerRunning = false;
      _isLocationTracking = false;

      _activeSession = null;
      _currentLocation = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end session: $e';
      notifyListeners();
    }
  }

  // ✅ ADD: Cancel/End Session (without saving to history as safe)
  Future<void> cancelSession() async {
    if (_activeSession == null) return;

    try {
      await _sessionService.endSession(_activeSession!.sessionId);

      // Clean up
      _timer?.cancel();
      _locationSubscription?.cancel();
      _isTimerRunning = false;
      _isLocationTracking = false;

      _activeSession = null;
      _currentLocation = null;
      _elapsedSeconds = 0;
      _remainingSeconds = 0;
      notifyListeners();

      print('🛑 Session cancelled');
    } catch (e) {
      _error = 'Failed to cancel session: $e';
      notifyListeners();
    }
  }

  // ✅ ADD: Pause Session
  void pauseSession() {
    _timer?.cancel();
    _isTimerRunning = false;
    notifyListeners();
  }

  // ✅ ADD: Resume Session
  void resumeSession() {
    if (_activeSession != null && _activeSession!.isActive) {
      _startTimer();
    }
  }

  // ✅ ADD: Extend Session Time
  Future<void> extendSession(int additionalMinutes) async {
    if (_activeSession == null) return;

    _remainingSeconds += additionalMinutes * 60;

    // Update in Firestore
    try {
      await _sessionService.extendSession(
        _activeSession!.sessionId,
        additionalMinutes,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to extend session: $e';
      notifyListeners();
    }
  }

  // Calculate times for display
  void _calculateTimes() {
    if (_activeSession == null) return;

    final now = DateTime.now();
    _elapsedSeconds = now.difference(_activeSession!.startTime).inSeconds;
    _remainingSeconds = _activeSession!.expectedEndTime
        .difference(now)
        .inSeconds;

    if (_remainingSeconds < 0) _remainingSeconds = 0;
  }

  // Format seconds to MM:SS
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // Get remaining time string
  String get remainingTimeString => formatTime(_remainingSeconds);

  // Get elapsed time string
  String get elapsedTimeString => formatTime(_elapsedSeconds);

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
