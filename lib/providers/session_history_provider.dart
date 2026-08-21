import 'package:flutter/material.dart';
import '../models/session_history_model.dart';
import '../services/session_history_service.dart';

class SessionHistoryProvider extends ChangeNotifier {
  final SessionHistoryService _historyService = SessionHistoryService();

  List<SessionHistoryModel> _sessions = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all';
  Map<String, dynamic> _stats = {};

  List<SessionHistoryModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  Map<String, dynamic> get stats => _stats;

  // Initialize - no async needed with SharedPreferences
  void initialize() {
    _loadSessions();
  }

  // Load sessions
  Future<void> _loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _historyService.getAllSessions();
      _applyFilter();
      _loadStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sessions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> _loadStats() async {
    _stats = {
      'totalSessions': await _historyService.getSessionCount(),
      'totalDistance': await _historyService.getTotalDistance(),
      'safeSessions': await _historyService.getSafeSessionsCount(),
      'totalAlerts': await _historyService.getTotalAlerts(),
    };
  }

  // Add new session
  Future<void> addSession(SessionHistoryModel session) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _historyService.saveSession(session);
      await _loadSessions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    await _historyService.deleteSession(sessionId);
    await _loadSessions();
  }

  // Clear all sessions
  Future<void> clearAllSessions() async {
    await _historyService.clearAllSessions();
    await _loadSessions();
  }

  // Set filter
  void setFilter(String newFilter) {
    _filter = newFilter;
    _applyFilter();
    notifyListeners();
  }

  // Apply filter
  Future<void> _applyFilter() async {
    final now = DateTime.now();

    switch (_filter) {
      case 'today':
        _sessions = await _historyService.getSessionsByDate(now);
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        final allSessions = await _historyService.getAllSessions();
        _sessions = allSessions
            .where((s) => s.startTime.isAfter(weekAgo))
            .toList();
        break;
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        final allSessions = await _historyService.getAllSessions();
        _sessions = allSessions
            .where((s) => s.startTime.isAfter(monthAgo))
            .toList();
        break;
      default:
        _sessions = await _historyService.getAllSessions();
    }
  }

  // Get stats
  Map<String, dynamic> getStats() {
    return _stats;
  }
}
