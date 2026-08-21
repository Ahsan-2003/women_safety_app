import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_history_model.dart';

class SessionHistoryService {
  static const String _boxName = 'session_history';

  // Initialize Hive
  Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<SessionHistoryModel>(_boxName);
    }
  }

  // Save session to local storage
  Future<void> saveSession(SessionHistoryModel session) async {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    await box.put(session.sessionId, session);
  }

  // Get all sessions (newest first)
  List<SessionHistoryModel> getAllSessions() {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    final sessions = box.values.toList();

    // Sort by start time (newest first)
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }

  // Get session by ID
  SessionHistoryModel? getSession(String sessionId) {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    return box.get(sessionId);
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    await box.delete(sessionId);
  }

  // Delete all sessions
  Future<void> clearAllSessions() async {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    await box.clear();
  }

  // Get session count
  int getSessionCount() {
    final box = Hive.box<SessionHistoryModel>(_boxName);
    return box.length;
  }

  // Get sessions for specific date
  List<SessionHistoryModel> getSessionsByDate(DateTime date) {
    return getAllSessions().where((session) {
      return session.startTime.year == date.year &&
          session.startTime.month == date.month &&
          session.startTime.day == date.day;
    }).toList();
  }

  // Get total distance walked
  double getTotalDistance() {
    return getAllSessions().fold(
      0,
      (sum, session) => sum + session.totalDistanceKm,
    );
  }

  // Get total sessions completed safely
  int getSafeSessionsCount() {
    return getAllSessions().where((s) => s.completedSafely).length;
  }

  // Get total alerts triggered
  int getTotalAlerts() {
    return getAllSessions().fold(0, (sum, s) => sum + s.alertsTriggered);
  }
}
