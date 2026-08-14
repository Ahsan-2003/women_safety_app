import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sos_provider.dart';
import 'home_screen.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SOSProvider>(
      builder: (context, sosProvider, child) {
        if (sosProvider.activeSOS == null) {
          return _buildTriggerScreen(context, sosProvider);
        }
        return _buildActiveSOSScreen(context, sosProvider);
      },
    );
  }

  // Screen shown before SOS is triggered
  Widget _buildTriggerScreen(BuildContext context, SOSProvider sosProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Warning Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Emergency SOS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'This will notify all your trusted contacts\nwith your current location',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // SOS Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: ElevatedButton(
                  onPressed: sosProvider.isLoading
                      ? null
                      : () async {
                          final success = await sosProvider.triggerSOS();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  sosProvider.error ?? 'SOS failed',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 10,
                    shadowColor: Colors.red.withOpacity(0.5),
                  ),
                  child: sosProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            Text(
              'Tap to send emergency alert',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // Screen shown after SOS is triggered
  Widget _buildActiveSOSScreen(BuildContext context, SOSProvider sosProvider) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Header
            const Text(
              '🚨 SOS ACTIVATED 🚨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Alert sent to ${sosProvider.activeSOS?.notifiedContacts.length ?? 0} contacts',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 30),

            // Location Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR LOCATION',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sosProvider.activeSOS?.address ?? 'Location unavailable',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Deterrent Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Siren Status
                _buildStatusChip(
                  context,
                  icon: Icons.volume_up,
                  label: 'Siren',
                  isActive: sosProvider.isSirenActive,
                ),
                const SizedBox(width: 20),
                // Flashlight Status
                _buildStatusChip(
                  context,
                  icon: Icons.flashlight_on,
                  label: 'Flashlight',
                  isActive: sosProvider.isFlashlightActive,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Stop Deterrents
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await sosProvider.stopAllDeterrents();
                },
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text(
                  'Stop Siren & Flashlight',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel SOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Confirm cancellation
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel SOS'),
                      content: const Text(
                        'Are you sure this was a false alarm?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Yes, Cancel SOS'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await sosProvider.cancelSOS();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "I'M SAFE - Cancel SOS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Status chip widget
  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
        Text(
          isActive ? 'ACTIVE' : 'OFF',
          style: TextStyle(
            color: isActive ? Colors.greenAccent : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
