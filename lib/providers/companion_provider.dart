import 'package:flutter/material.dart';
import '../models/companion_session_model.dart';
import '../services/companion_service.dart';

class CompanionProvider extends ChangeNotifier {
  final CompanionService _companionService = CompanionService();

  bool _isCompanion = false;
  bool _isLoading = false;
  String? _error;
  List<String> _monitoringUserIds = [];
  List<CompanionSessionModel> _activeSessions = [];
  List<Map<String, dynamic>> _sosAlerts = [];

  bool get isCompanion => _isCompanion;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get monitoringUserIds => _monitoringUserIds;
  List<CompanionSessionModel> get activeSessions => _activeSessions;
  List<Map<String, dynamic>> get sosAlerts => _sosAlerts;

  // Initialize companion mode
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isCompanion = await _companionService.isCompanion();
      if (_isCompanion) {
        _monitoringUserIds = await _companionService.getMonitoringUserIds();
        _startListening();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register as companion
  Future<bool> registerAsCompanion({
    required String displayName,
    required String phoneNumber,
  }) async {
    try {
      await _companionService.registerCompanion(
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      _isCompanion = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add user to monitor
  Future<void> addUserToMonitor(String userId) async {
    await _companionService.addUserToMonitor(userId);
    _monitoringUserIds = await _companionService.getMonitoringUserIds();
    notifyListeners();
  }

  // Start listening to active sessions
  void _startListening() {
    _companionService.getActiveSessionsStream().listen((sessions) {
      _activeSessions = sessions;
      notifyListeners();
    });

    _companionService.getSOSAlertsStream().listen((alerts) {
      _sosAlerts = alerts;
      notifyListeners();
    });
  }
}
