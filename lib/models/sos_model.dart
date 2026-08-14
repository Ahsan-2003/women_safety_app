class SOSModel {
  final String sosId;
  final String userId;
  final String sessionId;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final bool isActive;
  final List<String> notifiedContacts;

  SOSModel({
    required this.sosId,
    required this.userId,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.isActive = true,
    this.notifiedContacts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'sosId': sosId,
      'userId': userId,
      'sessionId': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'notifiedContacts': notifiedContacts,
    };
  }

  factory SOSModel.fromMap(Map<String, dynamic> map) {
    return SOSModel(
      sosId: map['sosId'] ?? '',
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      notifiedContacts: List<String>.from(map['notifiedContacts'] ?? []),
    );
  }
}
