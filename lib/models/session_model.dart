class SessionModel {
  final String sessionId;
  final String userId;
  final double startLatitude;
  final double startLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationAddress;
  final DateTime startTime;
  final DateTime expectedEndTime;
  final bool isActive;
  final bool isSafe;
  final List<String> notifiedContacts;
  final String shareableLink;

  // ADD THESE FIELDS
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastUpdateTime;

  SessionModel({
    required this.sessionId,
    required this.userId,
    required this.startLatitude,
    required this.startLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationAddress,
    required this.startTime,
    required this.expectedEndTime,
    this.isActive = true,
    this.isSafe = false,
    this.notifiedContacts = const [],
    required this.shareableLink,
    this.currentLatitude, // ADD THIS
    this.currentLongitude, // ADD THIS
    this.lastUpdateTime, // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'destinationAddress': destinationAddress,
      'startTime': startTime.toIso8601String(),
      'expectedEndTime': expectedEndTime.toIso8601String(),
      'isActive': isActive,
      'isSafe': isSafe,
      'notifiedContacts': notifiedContacts,
      'shareableLink': shareableLink,
      'currentLatitude': currentLatitude, // ADD THIS
      'currentLongitude': currentLongitude, // ADD THIS
      'lastUpdateTime': lastUpdateTime?.toIso8601String(), // ADD THIS
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      startLatitude: (map['startLatitude'] ?? 0.0).toDouble(),
      startLongitude: (map['startLongitude'] ?? 0.0).toDouble(),
      destinationLatitude: map['destinationLatitude']?.toDouble(),
      destinationLongitude: map['destinationLongitude']?.toDouble(),
      destinationAddress: map['destinationAddress'],
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : DateTime.now(),
      expectedEndTime: map['expectedEndTime'] != null
          ? DateTime.parse(map['expectedEndTime'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      isSafe: map['isSafe'] ?? false,
      notifiedContacts: List<String>.from(map['notifiedContacts'] ?? []),
      shareableLink: map['shareableLink'] ?? '',
      currentLatitude: map['currentLatitude']?.toDouble(), // ADD THIS
      currentLongitude: map['currentLongitude']?.toDouble(), // ADD THIS
      lastUpdateTime: map['lastUpdateTime'] != null
          ? DateTime.parse(map['lastUpdateTime'])
          : null, // ADD THIS
    );
  }
}
