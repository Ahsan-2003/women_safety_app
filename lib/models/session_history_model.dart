import 'dart:convert';

class SessionHistoryModel {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final String durationMinutes;
  final double startLatitude;
  final double startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String destinationAddress;
  final bool completedSafely;
  final double totalDistanceKm;
  final List<String> routePoints;
  final int alertsTriggered;

  SessionHistoryModel({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.startLatitude,
    required this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.destinationAddress = '',
    this.completedSafely = true,
    this.totalDistanceKm = 0,
    this.routePoints = const [],
    this.alertsTriggered = 0,
  });

  // Convert to Map for JSON storage
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'destinationAddress': destinationAddress,
      'completedSafely': completedSafely,
      'totalDistanceKm': totalDistanceKm,
      'routePoints': routePoints,
      'alertsTriggered': alertsTriggered,
    };
  }

  // Convert to JSON string
  String toJson() => jsonEncode(toMap());

  // Create from Map
  factory SessionHistoryModel.fromMap(Map<String, dynamic> map) {
    return SessionHistoryModel(
      sessionId: map['sessionId'] ?? '',
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'])
          : DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? '0',
      startLatitude: (map['startLatitude'] ?? 0.0).toDouble(),
      startLongitude: (map['startLongitude'] ?? 0.0).toDouble(),
      endLatitude: map['endLatitude']?.toDouble(),
      endLongitude: map['endLongitude']?.toDouble(),
      destinationAddress: map['destinationAddress'] ?? '',
      completedSafely: map['completedSafely'] ?? true,
      totalDistanceKm: (map['totalDistanceKm'] ?? 0.0).toDouble(),
      routePoints: List<String>.from(map['routePoints'] ?? []),
      alertsTriggered: map['alertsTriggered'] ?? 0,
    );
  }

  // Create from JSON string
  factory SessionHistoryModel.fromJson(String json) {
    return SessionHistoryModel.fromMap(jsonDecode(json));
  }
}
