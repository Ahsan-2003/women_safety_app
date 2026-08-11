class UserModel {
  final String uid;
  final String phoneNumber;
  final String? displayName;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.displayName,
    required this.createdAt,
  });

  // Convert Dart object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName ?? '',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Dart object from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
