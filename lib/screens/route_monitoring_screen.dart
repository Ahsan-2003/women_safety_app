import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety_app/screens/route_setup_screen.dart';
import '../providers/route_provider.dart';
import 'home_screen.dart';

class RouteMonitoringScreen extends StatelessWidget {
  const RouteMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        if (!routeProvider.isMonitoring) {
          // Not monitoring - show setup screen
          return const RouteSetupScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Route Monitoring Active'),
            backgroundColor: routeProvider.isDeviated
                ? Colors.red
                : Colors.green,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              const SizedBox(height: 40),

              // Status Indicator
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: routeProvider.isDeviated
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  routeProvider.isDeviated
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  size: 60,
                  color: routeProvider.isDeviated ? Colors.red : Colors.green,
                ),
              ),

              const SizedBox(height: 20),

              // Status Text
              Text(
                routeProvider.isDeviated ? 'DEVIATION DETECTED!' : 'ON ROUTE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: routeProvider.isDeviated ? Colors.red : Colors.green,
                ),
              ),

              const SizedBox(height: 10),

              // Deviation Distance
              Text(
                'Current deviation: ${routeProvider.currentDeviation.round()} meters',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // Threshold Info
              Text(
                'Threshold: ${routeProvider.activeRoute?.deviationThreshold.round() ?? 200} meters',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const Spacer(),

              // Warning if deviated
              if (routeProvider.isDeviated) ...[
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You are off your expected route. Contacts have been notified. If you are safe, tap below to reset.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    routeProvider.resetDeviation();
                  },
                  child: const Text("I'M SAFE - Reset Alert"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // Stop Monitoring Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Stop Monitoring'),
                          content: const Text('Stop route monitoring?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await routeProvider.stopMonitoring();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Monitoring'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
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
