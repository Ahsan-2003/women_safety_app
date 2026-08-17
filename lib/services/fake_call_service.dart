import 'package:shared_preferences/shared_preferences.dart';
import '../models/fake_call_model.dart';

class FakeCallService {
  static const String _callerNameKey = 'fake_call_caller_name';
  static const String _callerNumberKey = 'fake_call_caller_number';
  static const String _callScriptKey = 'fake_call_script';

  // Save caller settings
  Future<void> saveCallerSettings({
    required String callerName,
    required String callerNumber,
    String? callScript,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_callerNameKey, callerName);
    await prefs.setString(_callerNumberKey, callerNumber);
    if (callScript != null) {
      await prefs.setString(_callScriptKey, callScript);
    }
  }

  // Get saved caller settings
  Future<FakeCallModel?> getSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final callerName = prefs.getString(_callerNameKey);
    final callerNumber = prefs.getString(_callerNumberKey);

    if (callerName == null || callerNumber == null) {
      return null;
    }

    final callScript = prefs.getString(_callScriptKey);

    return FakeCallModel(
      callerName: callerName,
      callerNumber: callerNumber,
      callTime: DateTime.now(),
      callScript: callScript,
    );
  }

  // Get pre-written call scripts
  List<String> getCallScripts() {
    return [
      'Mom: "Hi honey, where are you? I need you to come home right now. There\'s an emergency."',
      'Dad: "Hey, I\'m outside waiting for you. Are you ready to go? We need to leave now."',
      'Sister: "Hey! I forgot my keys. Can you come home and open the door? I\'m locked out!"',
      'Friend: "Hey! I\'m at the restaurant. Where are you? We\'ve been waiting for 30 minutes!"',
      'Boss: "Hi, this is your manager. We need you to come to the office immediately. Urgent matter."',
      'Roommate: "Hey! There\'s a water leak in the apartment. Can you come back now?"',
      'Partner: "Hey babe, I\'m outside your location. Let\'s go, I have a surprise for you!"',
      'Doctor: "Hello, this is Dr. Smith\'s office calling. Your test results are ready."',
      'Landlord: "Hi, this is your landlord. There\'s an issue with the building. Please return home."',
      'School: "Hello, this is the school calling. Your child needs to be picked up early today."',
    ];
  }
}
