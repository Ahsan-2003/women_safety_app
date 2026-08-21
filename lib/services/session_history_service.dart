import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/session_history_model.dart';

class SessionHistoryService {
  static const String _storageKey = 'session_history_data';

  // Save session to local storage
  Future<void> saveSession(SessionHistoryModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing sessions
      final existingSessions = await getAllSessions();

      // Check if session already exists
      final sessionIndex = existingSessions.indexWhere(
        (s) => s.sessionId == session.sessionId,
      );

      if (sessionIndex != -1) {
        // Update existing session
        existingSessions[sessionIndex] = session;
      } else {
        // Add new session
        existingSessions.add(session);
      }

      // Convert to JSON list
      final sessionsJson = existingSessions.map((s) => s.toJson()).toList();

      // Save to SharedPreferences
      await prefs.setStringList(_storageKey, sessionsJson);

      print('✅ Session saved: ${session.sessionId}');
    } catch (e) {
      print('❌ Failed to save session: $e');
    }
  }

  // Get all sessions (newest first)
  Future<List<SessionHistoryModel>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList(_storageKey) ?? [];

      final sessions = sessionsJson
          .map((json) => SessionHistoryModel.fromJson(json))
          .toList();

      // Sort by start time (newest first)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      return sessions;
    } catch (e) {
      print('❌ Failed to get sessions: $e');
      return [];
    }
  }

  // Get session by ID
  Future<SessionHistoryModel?> getSession(String sessionId) async {
    final sessions = await getAllSessions();
    for (var session in sessions) {
      if (session.sessionId == sessionId) {
        return session;
      }
    }
    return null;
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getAllSessions();

      sessions.removeWhere((s) => s.sessionId == sessionId);

      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      await prefs.setStringList(_storageKey, sessionsJson);

      print('✅ Session deleted: $sessionId');
    } catch (e) {
      print('❌ Failed to delete session: $e');
    }
  }

  // Delete all sessions
  Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✅ All sessions cleared');
    } catch (e) {
      print('❌ Failed to clear sessions: $e');
    }
  }

  // Get session count
  Future<int> getSessionCount() async {
    final sessions = await getAllSessions();
    return sessions.length;
  }

  // Get sessions for specific date
  Future<List<SessionHistoryModel>> getSessionsByDate(DateTime date) async {
    final sessions = await getAllSessions();
    return sessions.where((session) {
      return session.startTime.year == date.year &&
          session.startTime.month == date.month &&
          session.startTime.day == date.day;
    }).toList();
  }

  // Get total distance walked
  Future<double> getTotalDistance() async {
    final sessions = await getAllSessions();
    double total = 0;
    for (var session in sessions) {
      total += session.totalDistanceKm;
    }
    return total;
  }

  // Get total sessions completed safely
  Future<int> getSafeSessionsCount() async {
    final sessions = await getAllSessions();
    return sessions.where((s) => s.completedSafely).length;
  }

  // Get total alerts triggered
  Future<int> getTotalAlerts() async {
    final sessions = await getAllSessions();
    int total = 0;
    for (var session in sessions) {
      total += session.alertsTriggered;
    }
    return total;
  }
}
