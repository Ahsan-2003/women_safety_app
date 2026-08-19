import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';
import '../services/notification_service.dart';
import 'location_provider.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final NotificationService _notificationService = NotificationService();
  final LocationProvider _locationProvider = LocationProvider();
  final Uuid _uuid = const Uuid();

  RouteModel? _activeRoute;
  StreamSubscription? _locationSubscription;
  double _currentDeviation = 0;
  bool _isMonitoring = false;
  bool _isDeviated = false;
  String? _error;
  String? _startAddress;
  String? _endAddress;

  RouteModel? get activeRoute => _activeRoute;
  double get currentDeviation => _currentDeviation;
  bool get isMonitoring => _isMonitoring;
  bool get isDeviated => _isDeviated;
  String? get error => _error;
  String? get startAddress => _startAddress;
  String? get endAddress => _endAddress;

  // Start route monitoring with automatic location detection
  Future<bool> startRouteMonitoring({
    required String sessionId,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? travelMode = 'walking',
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
        deviationThreshold: 200.0,
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
      _error = 'Failed to start monitoring: $e';
      notifyListeners();
      return false;
    }
  }

  // Monitor location updates for deviation
  void _startLocationMonitoring() {
    _locationSubscription?.cancel();

    _locationSubscription = _locationProvider.getLocationStream().listen(
      (position) async {
        if (_activeRoute == null) return;

        final deviation = _routeService.calculateDeviation(
          currentLat: position.latitude,
          currentLng: position.longitude,
          routePoints: _activeRoute!.waypoints,
        );

        _currentDeviation = deviation;

        if (deviation > _activeRoute!.deviationThreshold && !_isDeviated) {
          await _handleDeviation(
            position.latitude,
            position.longitude,
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

      await _routeService.saveDeviationAlert(alert);

      await _notificationService.showNotification(
        id: 300,
        title: '⚠️ ROUTE DEVIATION',
        body:
            'You are ${deviation.round()} meters off route. Contacts notified.',
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

  // Reset deviation flag
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
