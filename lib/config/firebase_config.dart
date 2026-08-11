// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseConfig {
  static FirebaseOptions get options {
    // These values come from your Firebase project
    return const FirebaseOptions(
      apiKey: 'AIzaSyBYsFuL9NSIpuwVO9zyh66f6CRz_MRKW6I',
      appId: '1:150199405061:web:33957111577a037b30aa6c',
      messagingSenderId: '150199405061',
      projectId: 'first-project-5720f',
      // Add these for iOS
      iosBundleId: 'com.example.womenSafetyApp',
    );
  }
}
