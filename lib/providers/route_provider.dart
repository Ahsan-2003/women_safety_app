import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  RouteModel? _activeRoute;
  StreamSubscription? _locationSubscription;
  double _currentDeviation = 0;
  bool _isMonitoring = false;
  bool _isDeviated = false;
  String? _error;

  RouteModel? get activeRoute => _activeRoute;
  double get currentDeviation => _currentDeviation;
  bool get isMonitoring => _isMonitoring;
  bool get isDeviated => _isDeviated;
  String? get error => _error;

  // Start route monitoring
  Future<bool> startRouteMonitoring({
    required String sessionId,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      _error = null;
      notifyListeners();

      // Calculate expected route
      final waypoints = _routeService.calculateExpectedRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );

      // Create route model
      final route = RouteModel(
        routeId: _uuid.v4(),
        sessionId: sessionId,
        waypoints: waypoints,
        deviationThreshold: 200.0, // 200 meters
        createdAt: DateTime.now(),
      );

      // Save route to Firestore
      await _routeService.saveRoute(route);
      _activeRoute = route;
      _isMonitoring = true;
      _isDeviated = false;
      _currentDeviation = 0;

      // Start location monitoring
      _startLocationMonitoring();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Monitor location updates for deviation
  void _startLocationMonitoring() {
    _locationSubscription?.cancel();

    _locationSubscription = _locationService.getLocationStream().listen(
      (location) async {
        if (_activeRoute == null) return;

        // Calculate deviation from expected route
        final deviation = _routeService.calculateDeviation(
          currentLat: location.latitude,
          currentLng: location.longitude,
          routePoints: _activeRoute!.waypoints,
        );

        _currentDeviation = deviation;

        // Check if deviation exceeds threshold
        if (deviation > _activeRoute!.deviationThreshold && !_isDeviated) {
          await _handleDeviation(
            location.latitude,
            location.longitude,
            deviation,
          );
        }

        notifyListeners();
      },
      onError: (error) {
        _error = 'Location monitoring error: $error';
        notifyListeners();
      },
    );
  }

  // Handle route deviation
  Future<void> _handleDeviation(
    double currentLat,
    double currentLng,
    double deviation,
  ) async {
    _isDeviated = true;

    try {
      // Create deviation alert
      final alert = DeviationAlert(
        alertId: _uuid.v4(),
        sessionId: _activeRoute!.sessionId,
        currentLatitude: currentLat,
        currentLongitude: currentLng,
        expectedLatitude: _activeRoute!.waypoints.first.latitude,
        expectedLongitude: _activeRoute!.waypoints.first.longitude,
        deviationDistance: deviation,
        timestamp: DateTime.now(),
      );

      // Save alert to Firestore
      await _routeService.saveDeviationAlert(alert);

      // Show notification
      await _notificationService.showNotification(
        id: 300,
        title: 'ROUTE DEVIATION DETECTED',
        body:
            'You are ${deviation.round()} meters off your expected route. Contacts will be notified.',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to handle deviation: $e';
      notifyListeners();
    }
  }

  // Stop route monitoring
  Future<void> stopMonitoring() async {
    _locationSubscription?.cancel();
    _isMonitoring = false;
    _isDeviated = false;
    _currentDeviation = 0;
    _activeRoute = null;
    notifyListeners();
  }

  // Reset deviation flag (after user confirms they're okay)
  void resetDeviation() {
    _isDeviated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
