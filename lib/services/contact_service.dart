import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to user's contacts subcollection
  CollectionReference _getContactsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('contacts');
  }

  // Add new contact
  Future<void> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final contactsRef = _getContactsRef(userId);
      final docRef = contactsRef.doc(); // Auto-generated ID

      final contact = ContactModel(
        id: docRef.id,
        name: name,
        phoneNumber: phoneNumber,
        addedAt: DateTime.now(),
      );

      await docRef.set(contact.toMap());
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  // Get all contacts as stream (real-time updates)
  Stream<List<ContactModel>> getContacts(String userId) {
    return _getContactsRef(
      userId,
    ).orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Delete contact
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _getContactsRef(userId).doc(contactId).delete();
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }
}
