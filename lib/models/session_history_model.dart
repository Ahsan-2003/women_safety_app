import 'package:hive/hive.dart';

part 'session_history_model.g.dart';

@HiveType(typeId: 0)
class SessionHistoryModel extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime endTime;

  @HiveField(3)
  final String durationMinutes;

  @HiveField(4)
  final double startLatitude;

  @HiveField(5)
  final double startLongitude;

  @HiveField(6)
  final double? endLatitude;

  @HiveField(7)
  final double? endLongitude;

  @HiveField(8)
  final String destinationAddress;

  @HiveField(9)
  final bool completedSafely;

  @HiveField(10)
  final double totalDistanceKm;

  @HiveField(11)
  final List<String> routePoints;

  @HiveField(12)
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
}
