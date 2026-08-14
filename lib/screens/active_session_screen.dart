import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'home_screen.dart'; // ADD THIS IMPORT

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        // If no active session, go back to home
        if (!sessionProvider.isSessionActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()), // FIXED
              (route) => false,
            );
          });
          return const SizedBox();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header - Session Active Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Session Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Elapsed: ${sessionProvider.elapsedTimeString}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Timer Display
                Text(
                  sessionProvider.remainingTimeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'remaining',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),

                const SizedBox(height: 20),

                // Destination
                if (sessionProvider.activeSession?.destinationAddress != null)
                  Text(
                    'To: ${sessionProvider.activeSession!.destinationAddress}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                const Spacer(),

                // Share Link Info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location link shared with trusted contacts',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // I'm Safe Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await sessionProvider.markSafe();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ), // FIXED
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 28),
                      label: const Text(
                        "I'M SAFE",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // SOS Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // SOS feature - coming next
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SOS triggered! Contacts notified.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      icon: const Icon(Icons.warning, size: 28),
                      label: const Text(
                        'SOS EMERGENCY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
