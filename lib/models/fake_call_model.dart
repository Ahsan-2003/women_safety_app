class FakeCallModel {
  final String callerName;
  final String callerNumber;
  final DateTime callTime;
  final bool isImmediate;
  final String? callScript;

  FakeCallModel({
    required this.callerName,
    required this.callerNumber,
    required this.callTime,
    this.isImmediate = true,
    this.callScript,
  });

  Map<String, dynamic> toMap() {
    return {
      'callerName': callerName,
      'callerNumber': callerNumber,
      'callTime': callTime.toIso8601String(),
      'isImmediate': isImmediate,
      'callScript': callScript,
    };
  }

  factory FakeCallModel.fromMap(Map<String, dynamic> map) {
    return FakeCallModel(
      callerName: map['callerName'] ?? '',
      callerNumber: map['callerNumber'] ?? '',
      callTime: map['callTime'] != null
          ? DateTime.parse(map['callTime'])
          : DateTime.now(),
      isImmediate: map['isImmediate'] ?? true,
      callScript: map['callScript'],
    );
  }
}
