import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../providers/location_provider.dart';
import 'home_screen.dart';

class RouteMonitoringScreen extends StatefulWidget {
  const RouteMonitoringScreen({super.key});

  @override
  State<RouteMonitoringScreen> createState() => _RouteMonitoringScreenState();
}

class _RouteMonitoringScreenState extends State<RouteMonitoringScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-detect current location when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(
        context,
        listen: false,
      ).getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        if (routeProvider.isMonitoring) {
          return const ActiveRouteMonitoringScreen();
        }
        return const RouteSetupScreen();
      },
    );
  }
}

// ============ SETUP SCREEN ============
class RouteSetupScreen extends StatefulWidget {
  const RouteSetupScreen({super.key});

  @override
  State<RouteSetupScreen> createState() => _RouteSetupScreenState();
}

class _RouteSetupScreenState extends State<RouteSetupScreen> {
  final _destinationController = TextEditingController();
  String _selectedMode = 'walking';
  bool _isLoading = false;

  final List<Map<String, String>> _travelModes = [
    {'value': 'walking', 'label': '🚶 Walking', 'icon': 'directions_walk'},
    {'value': 'driving', 'label': '🚗 Driving', 'icon': 'directions_car'},
    {'value': 'transit', 'label': '🚌 Transit', 'icon': 'directions_bus'},
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _startRouteMonitoring() async {
    final destination = _destinationController.text.trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    try {
      // Get current location
      final currentLocation = await locationProvider.getCurrentLocation();

      if (currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locationProvider.error ?? 'Unable to get your location',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Finding destination...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get destination coordinates from address
      final destinationLocation = await locationProvider
          .getCoordinatesFromAddress(destination);

      if (destinationLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not find "$destination". Try a more specific address.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Start route monitoring
      final success = await routeProvider.startRouteMonitoring(
        sessionId: 'standalone',
        startLat: currentLocation.latitude,
        startLng: currentLocation.longitude,
        endLat: destinationLocation['latitude']!,
        endLng: destinationLocation['longitude']!,
        travelMode: _selectedMode,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(routeProvider.error ?? 'Failed to start monitoring'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Success - show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route monitoring started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Monitoring')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location Card
            Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'START LOCATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locationProvider.currentAddress ??
                                  'Detecting your location...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (locationProvider.isLoading)
                        const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Arrow Down
            const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),

            const SizedBox(height: 20),

            // Destination Input
            Text(
              'Where are you going?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: 'Enter destination address',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Example: Home, Office, Mall, Station',
              ),
            ),

            const SizedBox(height: 20),

            // Quick Destinations
            Text(
              'Quick Options',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickDestination('🏠 Home')),
                const SizedBox(width: 10),
                Expanded(child: _buildQuickDestination('🏢 Work')),
                const SizedBox(width: 10),
                Expanded(child: _buildQuickDestination('🚉 Station')),
              ],
            ),

            const SizedBox(height: 20),

            // Travel Mode
            Text(
              'How are you traveling?',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: _travelModes.map((mode) {
                final isSelected = _selectedMode == mode['value'];
                return Expanded(
                  child: Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMode = mode['value']!;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(
                              mode['value'] == 'walking'
                                  ? Icons.directions_walk
                                  : mode['value'] == 'driving'
                                  ? Icons.directions_car
                                  : Icons.directions_bus,
                              color: isSelected ? Colors.white : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mode['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will be alerted if you go more than 200 meters off your expected route.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startRouteMonitoring,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.route),
                label: Text(
                  _isLoading ? 'Setting up...' : 'Start Route Monitoring',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

  Widget _buildQuickDestination(String label) {
    return OutlinedButton(
      onPressed: () {
        _destinationController.text = label.split(' ').last;
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

// ============ ACTIVE MONITORING SCREEN ============
class ActiveRouteMonitoringScreen extends StatelessWidget {
  const ActiveRouteMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Route Monitoring'),
            backgroundColor: routeProvider.isDeviated
                ? Colors.red
                : Colors.green,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              const SizedBox(height: 40),

              // Status Icon
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
                routeProvider.isDeviated ? 'OFF ROUTE!' : 'ON ROUTE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: routeProvider.isDeviated ? Colors.red : Colors.green,
                ),
              ),

              const SizedBox(height: 10),

              // Deviation Distance
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${routeProvider.currentDeviation.round()} meters from route',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const Spacer(),

              // Warning Message
              if (routeProvider.isDeviated) ...[
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⚠️ You are off your expected route!\n\nYour contacts have been notified.\n\nIf you are safe, tap the button below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    routeProvider.resetDeviation();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text("I'M SAFE - Continue"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // Stop Monitoring
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
                          content: const Text(
                            'Are you sure you want to stop route monitoring?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
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
