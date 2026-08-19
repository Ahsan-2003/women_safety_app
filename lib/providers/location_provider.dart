import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationProvider extends ChangeNotifier {
  // geocoding ^5.0.0 requires an instance instead of top-level functions
  final geocoding.Geocoding _geocodingClient = geocoding.Geocoding();

  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;

  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current location
  Future<Position?> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'Location permission permanently denied. Please enable in settings.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Check if location service is enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _error = 'Location services are disabled. Please enable GPS.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      _isLoading = false;
      notifyListeners();
      return position;
    } catch (e) {
      _error = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get address from coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      // ✅ geocoding ^5.0.0: call via the Geocoding instance
      List<geocoding.Placemark> placemarks = await _geocodingClient
          .placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Build address string
        final addressParts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty) {
          addressParts.add(placemark.subLocality!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }

        if (addressParts.isNotEmpty) {
          _currentAddress = addressParts.join(', ');
        } else {
          _currentAddress = 'Current Location';
        }
      } else {
        _currentAddress = 'Current Location';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Geocoding error: $e');
      _currentAddress = 'Current Location';
      notifyListeners();
    }
  }

  // Get coordinates from address - RETURNS SIMPLE MAP INSTEAD OF POSITION
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      // ✅ geocoding ^5.0.0: call via the Geocoding instance
      List<geocoding.Location> locations = await _geocodingClient
          .locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return {'latitude': location.latitude, 'longitude': location.longitude};
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get coordinates: $e');
      return null;
    }
  }

  // Get location stream for monitoring
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // Get simple location as map
  Future<Map<String, double>?> getLocationCoordinates() async {
    final position = await getCurrentLocation();
    if (position != null) {
      return {'latitude': position.latitude, 'longitude': position.longitude};
    }
    return null;
  }

  // Calculate distance between two points
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
