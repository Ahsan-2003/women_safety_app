import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  ConnectivityResult _connectionType = ConnectivityResult.wifi;

  bool get isOnline => _isOnline;
  ConnectivityResult get connectionType => _connectionType;

  // Initialize connectivity monitoring
  void initialize() {
    _checkInitialConnection();
    _startMonitoring();
  }

  // Check initial connection status
  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _connectionType = results.first;
        _isOnline = _connectionType != ConnectivityResult.none;
      }
    } catch (e) {
      _isOnline = false;
    }
  }

  // Start monitoring connection changes
  void _startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _connectionType = results.first;
        _isOnline = _connectionType != ConnectivityResult.none;
        debugPrint(
          'Connectivity changed: $_connectionType, Online: $_isOnline',
        );
      }
    });
  }

  // Check if connected to internet (not just network)
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && results.first != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Dispose subscription
  void dispose() {
    _subscription?.cancel();
  }
}
