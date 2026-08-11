import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    required Function(String errorMessage) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification for test numbers or Android auto-retrieve
          print('🔄 AUTO-VERIFICATION TRIGGERED');
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              message = 'Too many attempts. Try again later';
              break;
            case 'operation-not-allowed':
              message =
                  'Phone auth not enabled. Enable it in Firebase Console > Authentication > Sign-in method';
              break;
            default:
              message = e.message ?? 'Unknown error occurred';
          }
          print('❌ VERIFICATION FAILED: $message');
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📱 CODE SENT - Verification ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ AUTO-RETRIEVAL TIMEOUT');
        },
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
      print('❌ SEND OTP ERROR: $e');
    }
  }

  // Sign in with credential (for auto-verify)
  Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  // Verify OTP manually
  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user != null) {
        return await createUserInFirestore(user);
      }
    } catch (e) {
      print('❌ VERIFY OTP ERROR: $e');
      throw Exception('Invalid OTP code');
    }
    return null;
  }

  // Create user in Firestore (called by both auto-verify and manual verify)
  Future<UserModel> createUserInFirestore(User user) async {
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      UserModel newUser = UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      print('✅ NEW USER CREATED IN FIRESTORE');
      return newUser;
    } else {
      print('✅ EXISTING USER LOADED FROM FIRESTORE');
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
