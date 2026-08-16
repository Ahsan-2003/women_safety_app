class CheckinTimerModel {
  final String timerId;
  final String userId;
  final String sessionId;
  final DateTime startTime;
  final DateTime expectedEndTime;
  final DateTime? safeConfirmedTime;
  final bool isActive;
  final bool isSafe;
  final bool alertSent;
  final double? lastKnownLatitude;
  final double? lastKnownLongitude;

  CheckinTimerModel({
    required this.timerId,
    required this.userId,
    required this.sessionId,
    required this.startTime,
    required this.expectedEndTime,
    this.safeConfirmedTime,
    this.isActive = true,
    this.isSafe = false,
    this.alertSent = false,
    this.lastKnownLatitude,
    this.lastKnownLongitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'timerId': timerId,
      'userId': userId,
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'expectedEndTime': expectedEndTime.toIso8601String(),
      'safeConfirmedTime': safeConfirmedTime?.toIso8601String(),
      'isActive': isActive,
      'isSafe': isSafe,
      'alertSent': alertSent,
      'lastKnownLatitude': lastKnownLatitude,
      'lastKnownLongitude': lastKnownLongitude,
    };
  }

  factory CheckinTimerModel.fromMap(Map<String, dynamic> map) {
    return CheckinTimerModel(
      timerId: map['timerId'] ?? '',
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : DateTime.now(),
      expectedEndTime: map['expectedEndTime'] != null
          ? DateTime.parse(map['expectedEndTime'])
          : DateTime.now(),
      safeConfirmedTime: map['safeConfirmedTime'] != null
          ? DateTime.parse(map['safeConfirmedTime'])
          : null,
      isActive: map['isActive'] ?? true,
      isSafe: map['isSafe'] ?? false,
      alertSent: map['alertSent'] ?? false,
      lastKnownLatitude: map['lastKnownLatitude']?.toDouble(),
      lastKnownLongitude: map['lastKnownLongitude']?.toDouble(),
    );
  }
}
