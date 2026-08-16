import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety_app/providers/checkin_provider.dart';
import 'package:women_safety_app/providers/contact_provider.dart';
import 'package:women_safety_app/providers/session_provider.dart';
import 'package:women_safety_app/providers/sos_provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()), // ADD THIS
        ChangeNotifierProvider(create: (_) => CheckinProvider()), // ADD THIS
      ], // ADD THIS],
      child: MaterialApp(
        title: 'SafeWalk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(), // CHANGE: Use AuthGate instead of SplashScreen
      ),
    );
  }
}

// ADD THIS: AuthGate to handle navigation based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash while checking initial auth state
        if (authProvider.isAuthInitializing) {
          return const SplashScreen();
        }

        // If user is logged in, show HomeScreen
        // This handles: app start with saved login, and auto-verify
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        // Default: show LoginScreen
        return const LoginScreen();
      },
    );
  }
}
