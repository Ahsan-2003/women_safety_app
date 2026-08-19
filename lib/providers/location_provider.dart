import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
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
        _error = 'Location permission permanently denied';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
      } else {
        _currentAddress = 'Current Location';
      }
    } catch (e) {
      _currentAddress = 'Location: $lat, $lng';
    }
  }

  // Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get location stream
  Stream<Position> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
