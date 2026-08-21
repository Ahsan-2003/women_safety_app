import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/companion_user_model.dart';
import '../models/companion_session_model.dart';

class CompanionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register as companion
  Future<void> registerCompanion({
    required String displayName,
    required String phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final companion = CompanionUserModel(
      userId: user.uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      role: 'companion',
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('companions')
        .doc(user.uid)
        .set(companion.toMap());
  }

  // Add user to monitor
  Future<void> addUserToMonitor(String primaryUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('companions').doc(user.uid).update({
      'monitoringUserIds': FieldValue.arrayUnion([primaryUserId]),
    });
  }

  // Remove user from monitoring
  Future<void> removeUserFromMonitor(String primaryUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('companions').doc(user.uid).update({
      'monitoringUserIds': FieldValue.arrayRemove([primaryUserId]),
    });
  }

  // Get users being monitored
  Future<List<String>> getMonitoringUserIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _firestore.collection('companions').doc(user.uid).get();

    if (doc.exists) {
      return List<String>.from(doc.data()?['monitoringUserIds'] ?? []);
    }
    return [];
  }

  // Get active sessions for monitored users
  Stream<List<CompanionSessionModel>> getActiveSessionsStream() {
    return _firestore
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CompanionSessionModel.fromMap({
              ...data,
              'sessionId': doc.id,
            });
          }).toList();
        });
  }

  // Get SOS alerts for monitored users
  Stream<List<Map<String, dynamic>>> getSOSAlertsStream() {
    return _firestore
        .collection('sos_alerts')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // Get user info
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Check if user is a companion
  Future<bool> isCompanion() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('companions').doc(user.uid).get();

    return doc.exists;
  }
}
