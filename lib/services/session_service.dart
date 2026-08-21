import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';
import '../models/location_model.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate shareable link
  String generateShareableLink(String sessionId) {
    // Replace with your actual web hosting URL
    return 'https://safewalk-app.web.app/?session=$sessionId';
  }

  // Start a new session
  Future<String> startSession(SessionModel session) async {
    try {
      // Add shareable link to session
      final sessionWithLink = session.toMap();
      sessionWithLink['shareableLink'] = generateShareableLink(
        session.sessionId,
      );

      await _firestore
          .collection('sessions')
          .doc(session.sessionId)
          .set(sessionWithLink);

      return session.sessionId;
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  // Update location during session
  Future<void> updateLocation({
    required String sessionId,
    required LocationModel location,
  }) async {
    try {
      // Add location to subcollection
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('locations')
          .add(location.toMap());

      // Update current location in session document
      await _firestore.collection('sessions').doc(sessionId).update({
        'currentLatitude': location.latitude,
        'currentLongitude': location.longitude,
        'lastUpdateTime': location.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  // ✅ ADD THIS METHOD - End session (mark as safe)
  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isActive': false,
        'isSafe': true,
        'endTime': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // ✅ ADD THIS METHOD - Get active session for user
  Future<SessionModel?> getActiveSession(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return SessionModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ ADD THIS METHOD - Get session by ID (for web view)
  Future<SessionModel?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();

      if (doc.exists) {
        return SessionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ ADD THIS METHOD - Get session stream for real-time updates
  Stream<SessionModel?> sessionStream(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return SessionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
