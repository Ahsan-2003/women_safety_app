class CompanionSessionModel {
  final String sessionId;
  final String primaryUserId;
  final String primaryUserName;
  final String primaryUserPhone;
  final double currentLatitude;
  final double currentLongitude;
  final DateTime startTime;
  final DateTime expectedEndTime;
  final bool isActive;
  final bool isSOS;
  final String destinationAddress;
  final String shareableLink;

  CompanionSessionModel({
    required this.sessionId,
    required this.primaryUserId,
    required this.primaryUserName,
    required this.primaryUserPhone,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.startTime,
    required this.expectedEndTime,
    this.isActive = true,
    this.isSOS = false,
    this.destinationAddress = '',
    this.shareableLink = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'primaryUserId': primaryUserId,
      'primaryUserName': primaryUserName,
      'primaryUserPhone': primaryUserPhone,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'startTime': startTime.toIso8601String(),
      'expectedEndTime': expectedEndTime.toIso8601String(),
      'isActive': isActive,
      'isSOS': isSOS,
      'destinationAddress': destinationAddress,
      'shareableLink': shareableLink,
    };
  }

  factory CompanionSessionModel.fromMap(Map<String, dynamic> map) {
    return CompanionSessionModel(
      sessionId: map['sessionId'] ?? '',
      primaryUserId: map['primaryUserId'] ?? '',
      primaryUserName: map['primaryUserName'] ?? '',
      primaryUserPhone: map['primaryUserPhone'] ?? '',
      currentLatitude: (map['currentLatitude'] ?? 0.0).toDouble(),
      currentLongitude: (map['currentLongitude'] ?? 0.0).toDouble(),
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : DateTime.now(),
      expectedEndTime: map['expectedEndTime'] != null
          ? DateTime.parse(map['expectedEndTime'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      isSOS: map['isSOS'] ?? false,
      destinationAddress: map['destinationAddress'] ?? '',
      shareableLink: map['shareableLink'] ?? '',
    );
  }
}
