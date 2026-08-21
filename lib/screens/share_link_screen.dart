import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class ShareLinkScreen extends StatelessWidget {
  const ShareLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final session = sessionProvider.activeSession;

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Share Location')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share this link with your trusted contacts so they can see your live location.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Shareable Link
            Text(
              'Your Shareable Link',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.shareableLink,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: session.shareableLink),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Session Info
            Text(
              'Session Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Started'),
                    subtitle: Text(session.startTime.toString()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_off),
                    title: const Text('Expected End'),
                    subtitle: Text(session.expectedEndTime.toString()),
                  ),
                  if (session.destinationAddress != null)
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Destination'),
                      subtitle: Text(session.destinationAddress!),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Share via Apps
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Share via system dialog
                  // You can use share_plus package for this
                },
                icon: const Icon(Icons.share),
                label: const Text('Share via Apps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
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
}
