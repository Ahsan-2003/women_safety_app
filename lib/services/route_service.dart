import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Distance _distance = const Distance();

  // Calculate expected route between two points (simplified straight line)
  List<RoutePoint> calculateExpectedRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    // For now, create a simple route with start, midpoint, and end
    // In production, use Google Maps Directions API for actual route
    final points = <RoutePoint>[];

    points.add(RoutePoint(latitude: startLat, longitude: startLng));

    // Add intermediate points (every 25% of the way)
    for (int i = 1; i <= 3; i++) {
      final fraction = i / 4.0;
      points.add(
        RoutePoint(
          latitude: startLat + (endLat - startLat) * fraction,
          longitude: startLng + (endLng - startLng) * fraction,
        ),
      );
    }

    points.add(RoutePoint(latitude: endLat, longitude: endLng));

    return points;
  }

  // Calculate distance from point to route
  double calculateDeviation({
    required double currentLat,
    required double currentLng,
    required List<RoutePoint> routePoints,
  }) {
    if (routePoints.isEmpty) return 0;

    final currentPoint = LatLng(currentLat, currentLng);
    double minDistance = double.infinity;

    // Check distance to each route segment
    for (int i = 0; i < routePoints.length - 1; i++) {
      final segmentStart = routePoints[i].toLatLng();
      final segmentEnd = routePoints[i + 1].toLatLng();

      final distance = _distanceToSegment(
        currentPoint,
        segmentStart,
        segmentEnd,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  // Calculate distance from point to line segment
  double _distanceToSegment(LatLng point, LatLng start, LatLng end) {
    final distanceToStart = _distance(point, start);
    final distanceToEnd = _distance(point, end);

    return min(distanceToStart, distanceToEnd);
  }

  // Save route to Firestore
  Future<void> saveRoute(RouteModel route) async {
    try {
      await _firestore
          .collection('routes')
          .doc(route.routeId)
          .set(route.toMap());
    } catch (e) {
      throw Exception('Failed to save route: $e');
    }
  }

  // Save deviation alert
  Future<void> saveDeviationAlert(DeviationAlert alert) async {
    try {
      await _firestore
          .collection('deviation_alerts')
          .doc(alert.alertId)
          .set(alert.toMap());
    } catch (e) {
      throw Exception('Failed to save deviation alert: $e');
    }
  }
}
