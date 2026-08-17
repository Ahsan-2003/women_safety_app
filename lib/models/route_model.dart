import 'package:latlong2/latlong.dart';

class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class RouteModel {
  final String routeId;
  final String sessionId;
  final List<RoutePoint> waypoints;
  final double deviationThreshold; // in meters (default 200m)
  final DateTime createdAt;

  RouteModel({
    required this.routeId,
    required this.sessionId,
    required this.waypoints,
    this.deviationThreshold = 200.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'sessionId': sessionId,
      'waypoints': waypoints.map((p) => p.toMap()).toList(),
      'deviationThreshold': deviationThreshold,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      routeId: map['routeId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      waypoints: (map['waypoints'] as List? ?? [])
          .map((p) => RoutePoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      deviationThreshold: (map['deviationThreshold'] ?? 200.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class DeviationAlert {
  final String alertId;
  final String sessionId;
  final double currentLatitude;
  final double currentLongitude;
  final double expectedLatitude;
  final double expectedLongitude;
  final double deviationDistance;
  final DateTime timestamp;

  DeviationAlert({
    required this.alertId,
    required this.sessionId,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.expectedLatitude,
    required this.expectedLongitude,
    required this.deviationDistance,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'sessionId': sessionId,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'expectedLatitude': expectedLatitude,
      'expectedLongitude': expectedLongitude,
      'deviationDistance': deviationDistance,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
