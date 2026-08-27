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

  // End session (mark as safe)
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

  // ✅ ADD: Cancel session (without marking as safe)
  Future<void> cancelSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isActive': false,
        'isSafe': false,
        'cancelledAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to cancel session: $e');
    }
  }

  // ✅ ADD: Extend session time
  Future<void> extendSession(String sessionId, int additionalMinutes) async {
    try {
      final docRef = _firestore.collection('sessions').doc(sessionId);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentEndTime = DateTime.parse(data['expectedEndTime']);
        final newEndTime = currentEndTime.add(
          Duration(minutes: additionalMinutes),
        );

        await docRef.update({'expectedEndTime': newEndTime.toIso8601String()});
      }
    } catch (e) {
      throw Exception('Failed to extend session: $e');
    }
  }

  // ✅ ADD: Pause session
  Future<void> pauseSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isPaused': true,
        'pausedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to pause session: $e');
    }
  }

  // ✅ ADD: Resume session
  Future<void> resumeSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isPaused': false,
        'resumedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to resume session: $e');
    }
  }

  // Get active session for user
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

  // Get session by ID (for web view)
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

  // Get session stream for real-time updates
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

  // ✅ ADD: Get all sessions for user
  Future<List<SessionModel>> getUserSessions(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      return query.docs.map((doc) {
        return SessionModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ✅ ADD: Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }
}
