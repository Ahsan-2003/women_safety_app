import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

class ContactProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;
  Stream<List<ContactModel>>? _contactsStream;

  List<ContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize - start listening to contacts
  void loadContacts() {
    final user = _auth.currentUser;
    if (user == null) return;

    _contactsStream = _contactService.getContacts(user.uid);
    _contactsStream!.listen((contactsList) {
      _contacts = contactsList;
      notifyListeners();
    });
  }

  // Add contact
  Future<bool> addContact(String name, String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _contactService.addContact(
        userId: user.uid,
        name: name,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete contact
  Future<bool> deleteContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _contactService.deleteContact(
        userId: user.uid,
        contactId: contactId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
