class ContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime addedAt;
  final bool isActive;
  final String? fcmToken; // ADD THIS

  ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.addedAt,
    this.isActive = true,
    this.fcmToken, // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'addedAt': addedAt.toIso8601String(),
      'isActive': isActive,
      'fcmToken': fcmToken, // ADD THIS
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.parse(map['addedAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      fcmToken: map['fcmToken'], // ADD THIS
    );
  }
}
