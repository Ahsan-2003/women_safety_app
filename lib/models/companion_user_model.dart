class CompanionUserModel {
  final String userId;
  final String phoneNumber;
  final String displayName;
  final String role; // 'primary' or 'companion'
  final List<String> monitoringUserIds; // Users this companion monitors
  final List<String> fcmTokens;
  final DateTime createdAt;

  CompanionUserModel({
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    this.role = 'companion',
    this.monitoringUserIds = const [],
    this.fcmTokens = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role,
      'monitoringUserIds': monitoringUserIds,
      'fcmTokens': fcmTokens,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompanionUserModel.fromMap(Map<String, dynamic> map) {
    return CompanionUserModel(
      userId: map['userId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'companion',
      monitoringUserIds: List<String>.from(map['monitoringUserIds'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
