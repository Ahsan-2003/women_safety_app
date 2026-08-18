import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_manager_provider.dart';

class OfflineStatusWidget extends StatelessWidget {
  const OfflineStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineManagerProvider>(
      builder: (context, provider, child) {
        if (provider.isOnline) {
          return const SizedBox.shrink(); // Hidden when online
        }

        return Container(
          width: double.infinity,
          color: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OFFLINE MODE - SMS alerts active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
