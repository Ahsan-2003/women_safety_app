import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_manager_provider.dart';

class OfflineStatusWidget extends StatelessWidget {
  const OfflineStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineManagerProvider>(
      builder: (context, provider, child) {
        // Show banner only when offline
        if (provider.isOnline) {
          return const SizedBox.shrink(); // Hidden when online
        }

        return Container(
          width: double.infinity,
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFFLINE MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'SMS alerts active - ${provider.queueCount} pending',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Retry button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: () async {
                  await provider.checkConnection();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
