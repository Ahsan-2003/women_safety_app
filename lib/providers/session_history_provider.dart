import 'package:flutter/material.dart';
import '../models/session_history_model.dart';
import '../services/session_history_service.dart';

class SessionHistoryProvider extends ChangeNotifier {
  final SessionHistoryService _historyService = SessionHistoryService();

  List<SessionHistoryModel> _sessions = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'all'; // all, today, week, month

  List<SessionHistoryModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  // Initialize
  Future<void> initialize() async {
    await _historyService.initialize();
    _loadSessions();
  }

  // Load sessions
  void _loadSessions() {
    _sessions = _historyService.getAllSessions();
    notifyListeners();
  }

  // Add new session
  Future<void> addSession(SessionHistoryModel session) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _historyService.saveSession(session);
      _loadSessions();
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
    _loadSessions();
  }

  // Clear all sessions
  Future<void> clearAllSessions() async {
    await _historyService.clearAllSessions();
    _loadSessions();
  }

  // Set filter
  void setFilter(String newFilter) {
    _filter = newFilter;
    _applyFilter();
  }

  // Apply filter
  void _applyFilter() {
    final now = DateTime.now();

    switch (_filter) {
      case 'today':
        _sessions = _historyService.getSessionsByDate(now);
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        _sessions = _historyService
            .getAllSessions()
            .where((s) => s.startTime.isAfter(weekAgo))
            .toList();
        break;
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        _sessions = _historyService
            .getAllSessions()
            .where((s) => s.startTime.isAfter(monthAgo))
            .toList();
        break;
      default:
        _sessions = _historyService.getAllSessions();
    }

    notifyListeners();
  }

  // Get stats
  Map<String, dynamic> getStats() {
    return {
      'totalSessions': _historyService.getSessionCount(),
      'totalDistance': _historyService.getTotalDistance(),
      'safeSessions': _historyService.getSafeSessionsCount(),
      'totalAlerts': _historyService.getTotalAlerts(),
    };
  }
}
