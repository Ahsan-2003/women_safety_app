import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../models/location_model.dart';
import '../services/session_service.dart';
import '../services/location_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  SessionModel? _activeSession;
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;

  SessionModel? get activeSession => _activeSession;
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSessionActive =>
      _activeSession != null && _activeSession!.isActive;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds => _remainingSeconds;

  // Check for existing active session
  Future<void> checkActiveSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _activeSession = await _sessionService.getActiveSession(user.uid);
      if (_activeSession != null) {
        _calculateTimes();
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

      final session = SessionModel(
        sessionId: sessionId,
        userId: user.uid,
        startLatitude: location.latitude,
        startLongitude: location.longitude,
        destinationAddress: destinationAddress,
        startTime: now,
        expectedEndTime: now.add(Duration(minutes: durationMinutes)),
        shareableLink: 'https://safewalk.app/session/$sessionId',
      );

      await _sessionService.startSession(session);
      _activeSession = session;
      _currentLocation = location;
      _remainingSeconds = durationMinutes * 60;

      // Start location tracking
      _startLocationTracking(sessionId);
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
    _locationService.getLocationStream().listen(
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
        notifyListeners();
      },
    );
  }

  // Start countdown timer
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!isSessionActive) return false;

      _elapsedSeconds++;
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        // Time's up - trigger alert
        await _endSession(safe: false);
        return false;
      }

      notifyListeners();
      return true;
    });
  }

  // End session (safe arrival or timeout)
  Future<void> _endSession({required bool safe}) async {
    if (_activeSession == null) return;

    try {
      await _sessionService.endSession(_activeSession!.sessionId);
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
    await _endSession(safe: true);
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
}
