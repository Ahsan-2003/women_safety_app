import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
          return const ActiveRouteMapScreen();
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

      Map<String, double>? destinationCoords;

      try {
        destinationCoords = await locationProvider.getCoordinatesFromAddress(
          destination,
        );
      } catch (e) {
        destinationCoords = null;
      }

      // Fallback for testing
      if (destinationCoords == null) {
        destinationCoords = {
          'latitude': currentLocation.latitude + 0.01,
          'longitude': currentLocation.longitude + 0.01,
        };

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using test destination 1km away'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      final success = await routeProvider.startRouteMonitoring(
        sessionId: 'standalone',
        startLat: currentLocation.latitude,
        startLng: currentLocation.longitude,
        endLat: destinationCoords['latitude']!,
        endLng: destinationCoords['longitude']!,
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
      appBar: AppBar(title: const Text('Route Monitoring Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location
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
                              'START',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              locationProvider.currentAddress ?? 'Detecting...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
            const SizedBox(height: 16),

            // Destination Input
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: 'Enter destination (e.g., Karachi, Lahore)',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Icon(Icons.map),
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

            const SizedBox(height: 20),

            // Test hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 For testing, type a city name like "Karachi" or "Lahore". If not found, a test route will be created.',
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ACTIVE MAP SCREEN ============
class ActiveRouteMapScreen extends StatelessWidget {
  const ActiveRouteMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, child) {
        GoogleMapController? mapController;

        return Scaffold(
          body: Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: routeProvider.startPosition ?? const LatLng(0, 0),
                  zoom: 15,
                ),
                markers: routeProvider.routeMarkers,
                polylines: routeProvider.routePolylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  mapController = controller;

                  // Animate camera to show entire route
                  _fitRouteInView(controller, routeProvider);
                },
              ),

              // Top Status Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  decoration: BoxDecoration(
                    color: routeProvider.isDeviated ? Colors.red : Colors.green,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        routeProvider.isDeviated
                            ? Icons.warning
                            : Icons.check_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routeProvider.isDeviated
                                  ? 'OFF ROUTE!'
                                  : 'ON ROUTE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${routeProvider.currentDeviation.round()}m deviation',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      // Stop Button
                      IconButton(
                        icon: const Icon(
                          Icons.stop_circle,
                          color: Colors.white,
                          size: 35,
                        ),
                        onPressed: () => _confirmStop(context, routeProvider),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Stats Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.route,
                            label: 'Total',
                            value:
                                '${(routeProvider.totalDistance / 1000).toStringAsFixed(2)} km',
                          ),
                          _buildStatItem(
                            icon: Icons.timelapse,
                            label: 'Remaining',
                            value:
                                '${(routeProvider.remainingDistance / 1000).toStringAsFixed(2)} km',
                          ),
                          _buildStatItem(
                            icon: Icons.speed,
                            label: 'Deviation',
                            value: '${routeProvider.currentDeviation.round()}m',
                            valueColor: routeProvider.isDeviated
                                ? Colors.red
                                : Colors.green,
                          ),
                        ],
                      ),

                      if (routeProvider.isDeviated) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            routeProvider.resetDeviation();
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text("I'M SAFE - Continue"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fit route in view
  void _fitRouteInView(GoogleMapController controller, RouteProvider provider) {
    if (provider.startPosition != null && provider.endPosition != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          provider.startPosition!.latitude < provider.endPosition!.latitude
              ? provider.startPosition!.latitude
              : provider.endPosition!.latitude,
          provider.startPosition!.longitude < provider.endPosition!.longitude
              ? provider.startPosition!.longitude
              : provider.endPosition!.longitude,
        ),
        northeast: LatLng(
          provider.startPosition!.latitude > provider.endPosition!.latitude
              ? provider.startPosition!.latitude
              : provider.endPosition!.latitude,
          provider.startPosition!.longitude > provider.endPosition!.longitude
              ? provider.startPosition!.longitude
              : provider.endPosition!.longitude,
        ),
      );

      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  // Stat item widget
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  // Confirm stop
  Future<void> _confirmStop(
    BuildContext context,
    RouteProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Monitoring'),
        content: const Text('Are you sure you want to stop route monitoring?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.stopMonitoring();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
