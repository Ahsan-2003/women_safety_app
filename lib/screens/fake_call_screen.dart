import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fake_call_provider.dart';
import 'fake_call_settings_screen.dart';
import 'home_screen.dart';

class FakeCallScreen extends StatelessWidget {
  const FakeCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FakeCallProvider>(
      builder: (context, provider, child) {
        if (provider.isCallActive && provider.activeCall != null) {
          return _buildIncomingCallScreen(context, provider);
        }
        return _buildTriggerScreen(context, provider);
      },
    );
  }

  // Screen to trigger fake call
  Widget _buildTriggerScreen(BuildContext context, FakeCallProvider provider) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake Call')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Phone Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_in_talk,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Fake Call',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate an incoming call to exit\nuncomfortable situations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 40),

            // Immediate Call Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await provider.startImmediateCall();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Failed to start call'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.call),
                label: const Text(
                  'Call Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Schedule Section
            const Text(
              'Or schedule a call',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildScheduleButton(
                    context,
                    delay: 10,
                    label: '10s',
                    provider: provider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScheduleButton(
                    context,
                    delay: 30,
                    label: '30s',
                    provider: provider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScheduleButton(
                    context,
                    delay: 60,
                    label: '1 min',
                    provider: provider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScheduleButton(
                    context,
                    delay: 120,
                    label: '2 min',
                    provider: provider,
                  ),
                ),
              ],
            ),

            // Scheduled countdown
            if (provider.isScheduled) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Call in ${provider.scheduledDelay} seconds...',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.cancelScheduledCall(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Settings Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FakeCallSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Call Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Schedule button widget
  Widget _buildScheduleButton(
    BuildContext context, {
    required int delay,
    required String label,
    required FakeCallProvider provider,
  }) {
    return OutlinedButton(
      onPressed: () {
        provider.scheduleCall(delayInSeconds: delay);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }

  // Incoming call screen
  Widget _buildIncomingCallScreen(
    BuildContext context,
    FakeCallProvider provider,
  ) {
    final call = provider.activeCall!;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Caller Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Text(
                call.callerName.isNotEmpty
                    ? call.callerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Caller Name
            Text(
              call.callerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Caller Number
            Text(
              call.callerNumber,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 10),

            // Call Status
            Text(
              provider.isCallConnected ? 'Call Connected' : 'Incoming Call...',
              style: TextStyle(
                fontSize: 14,
                color: provider.isCallConnected
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
            ),

            const Spacer(),

            // Call Script (shown when connected)
            if (provider.isCallConnected && call.callScript != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  call.callScript!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Call Action Buttons
            if (!provider.isCallConnected) ...[
              // Incoming call: Answer/Decline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    context,
                    icon: Icons.call,
                    color: Colors.green,
                    label: 'Answer',
                    onPressed: () async {
                      await provider.answerCall();
                    },
                  ),
                  _buildCallButton(
                    context,
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onPressed: () async {
                      await provider.declineCall();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ] else ...[
              // Connected: End call
              _buildCallButton(
                context,
                icon: Icons.call_end,
                color: Colors.red,
                label: 'End Call',
                onPressed: () async {
                  await provider.endCall();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Call button widget
  Widget _buildCallButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color,
          onPressed: onPressed,
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
