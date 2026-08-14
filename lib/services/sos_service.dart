import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sos_model.dart';
import '../models/contact_model.dart';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Trigger SOS
  Future<SOSModel?> triggerSOS({
    required String sessionId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create SOS document
      final sosRef = _firestore.collection('sos_alerts').doc();
      final sos = SOSModel(
        sosId: sosRef.id,
        userId: user.uid,
        sessionId: sessionId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: DateTime.now(),
      );

      await sosRef.set(sos.toMap());

      // Get user's contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .get();

      // Update notified contacts
      List<String> notifiedContacts = [];
      for (var doc in contactsSnapshot.docs) {
        final contact = ContactModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        notifiedContacts.add(contact.phoneNumber);
      }

      await sosRef.update({'notifiedContacts': notifiedContacts});

      return SOSModel.fromMap({
        ...sos.toMap(),
        'notifiedContacts': notifiedContacts,
      });
    } catch (e) {
      throw Exception('Failed to trigger SOS: $e');
    }
  }

  // Cancel SOS (false alarm)
  Future<void> cancelSOS(String sosId) async {
    try {
      await _firestore.collection('sos_alerts').doc(sosId).update({
        'isActive': false,
        'cancelledAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to cancel SOS: $e');
    }
  }

  // Get user's trusted contacts for SMS
  Future<List<ContactModel>> getTrustedContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .get();

      return snapshot.docs.map((doc) {
        return ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
