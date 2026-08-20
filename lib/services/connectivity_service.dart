import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  ConnectivityResult _connectionType = ConnectivityResult.wifi;

  bool get isOnline => _isOnline;
  ConnectivityResult get connectionType => _connectionType;

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    await _checkInitialConnection();
    _startMonitoring();
  }

  // Check initial connection status
  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      _isOnline = false;
    }
    notifyListeners();
  }

  // Start monitoring connection changes
  void _startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
      notifyListeners();
    });
  }

  // Update connection status
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isNotEmpty) {
      _connectionType = results.first;
      _isOnline = _connectionType != ConnectivityResult.none;
    } else {
      _isOnline = false;
    }
    debugPrint('📶 Connectivity: $_connectionType, Online: $_isOnline');
  }

  // Check if connected to internet
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && results.first != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Dispose subscription
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
