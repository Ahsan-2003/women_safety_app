import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  // Map related
  LatLng? _currentPosition;
  LatLng? _startPosition;
  LatLng? _endPosition;
  Set<Polyline> _routePolylines = {};
  Set<Marker> _routeMarkers = {};
  double _totalDistance = 0;
  double _remainingDistance = 0;

  RouteModel? get activeRoute => _activeRoute;
  double get currentDeviation => _currentDeviation;
  bool get isMonitoring => _isMonitoring;
  bool get isDeviated => _isDeviated;
  String? get error => _error;
  LatLng? get currentPosition => _currentPosition;
  LatLng? get startPosition => _startPosition;
  LatLng? get endPosition => _endPosition;
  Set<Polyline> get routePolylines => _routePolylines;
  Set<Marker> get routeMarkers => _routeMarkers;
  double get totalDistance => _totalDistance;
  double get remainingDistance => _remainingDistance;

  // Start route monitoring
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

      // Set positions
      _startPosition = LatLng(startLat, startLng);
      _endPosition = LatLng(endLat, endLng);
      _currentPosition = LatLng(startLat, startLng);

      // Calculate route points
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

      await _routeService.saveRoute(route);
      _activeRoute = route;
      _isMonitoring = true;
      _isDeviated = false;
      _currentDeviation = 0;

      // Calculate total distance
      _totalDistance = _calculateTotalDistance(waypoints);
      _remainingDistance = _totalDistance;

      // Build map elements
      _buildMapElements();

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

  // Calculate total route distance
  double _calculateTotalDistance(List<RoutePoint> waypoints) {
    double total = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      total += _locationProvider.calculateDistance(
        startLat: waypoints[i].latitude,
        startLng: waypoints[i].longitude,
        endLat: waypoints[i + 1].latitude,
        endLng: waypoints[i + 1].longitude,
      );
    }
    return total;
  }

  // Build map elements (markers and polylines)
  void _buildMapElements() {
    _routeMarkers = {};
    _routePolylines = {};

    // Add start marker
    if (_startPosition != null) {
      _routeMarkers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
    }

    // Add end marker
    if (_endPosition != null) {
      _routeMarkers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Add current position marker
    if (_currentPosition != null) {
      _routeMarkers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }

    // Build route polyline
    if (_activeRoute != null && _activeRoute!.waypoints.isNotEmpty) {
      final points = _activeRoute!.waypoints.map((wp) {
        return LatLng(wp.latitude, wp.longitude);
      }).toList();

      _routePolylines.add(
        Polyline(
          polylineId: const PolylineId('expected_route'),
          points: points,
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      );

      // Add corridor polyline (showing 200m threshold)
      _routePolylines.add(
        Polyline(
          polylineId: const PolylineId('corridor'),
          points: points,
          color: Colors.blue.withOpacity(0.2),
          width: 20,
          geodesic: true,
        ),
      );
    }
  }

  // Monitor location updates
  void _startLocationMonitoring() {
    _locationSubscription?.cancel();

    _locationSubscription = _locationProvider.getLocationStream().listen(
      (position) async {
        if (_activeRoute == null) return;

        _currentPosition = LatLng(position.latitude, position.longitude);

        // Calculate deviation
        final deviation = _routeService.calculateDeviation(
          currentLat: position.latitude,
          currentLng: position.longitude,
          routePoints: _activeRoute!.waypoints,
        );

        _currentDeviation = deviation;
        _remainingDistance = _calculateRemainingDistance(
          position.latitude,
          position.longitude,
        );

        // Update current position marker
        _updateCurrentPositionMarker();

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

  // Calculate remaining distance
  double _calculateRemainingDistance(double currentLat, double currentLng) {
    if (_endPosition == null) return 0;

    return _locationProvider.calculateDistance(
      startLat: currentLat,
      startLng: currentLng,
      endLat: _endPosition!.latitude,
      endLng: _endPosition!.longitude,
    );
  }

  // Update current position marker
  void _updateCurrentPositionMarker() {
    _routeMarkers.removeWhere(
      (marker) => marker.markerId == const MarkerId('current'),
    );

    if (_currentPosition != null) {
      _routeMarkers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }
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
        body: 'You are ${deviation.round()} meters off route!',
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to handle deviation: $e';
      notifyListeners();
    }
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    _locationSubscription?.cancel();
    _isMonitoring = false;
    _isDeviated = false;
    _currentDeviation = 0;
    _activeRoute = null;
    _routePolylines = {};
    _routeMarkers = {};
    _currentPosition = null;
    _startPosition = null;
    _endPosition = null;
    notifyListeners();
  }

  // Reset deviation
  void resetDeviation() {
    _isDeviated = false;
    notifyListeners();
  }

  // Get route for Google Maps
  Set<Polyline> getRoutePolyline() {
    return _routePolylines;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
