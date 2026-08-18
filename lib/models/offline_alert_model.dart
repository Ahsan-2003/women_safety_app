class OfflineAlertModel {
  final String alertId;
  final String userId;
  final String type; // 'sos', 'checkin_timeout', 'route_deviation'
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final bool isSent;
  final String message;

  OfflineAlertModel({
    required this.alertId,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.isSent = false,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'userId': userId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'isSent': isSent,
      'message': message,
    };
  }

  factory OfflineAlertModel.fromMap(Map<String, dynamic> map) {
    return OfflineAlertModel(
      alertId: map['alertId'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isSent: map['isSent'] ?? false,
      message: map['message'] ?? '',
    );
  }
}

class SmsQueueItem {
  final String id;
  final String phoneNumber;
  final String message;
  final DateTime queuedAt;
  bool sent;
  DateTime? sentAt;

  SmsQueueItem({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.queuedAt,
    this.sent = false,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'message': message,
      'queuedAt': queuedAt.toIso8601String(),
      'sent': sent,
      'sentAt': sentAt?.toIso8601String(),
    };
  }

  factory SmsQueueItem.fromMap(Map<String, dynamic> map) {
    return SmsQueueItem(
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      message: map['message'] ?? '',
      queuedAt: map['queuedAt'] != null
          ? DateTime.parse(map['queuedAt'])
          : DateTime.now(),
      sent: map['sent'] ?? false,
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
    );
  }
}
