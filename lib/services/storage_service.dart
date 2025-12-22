import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';
import '../models/daily_stats.dart';

class StorageService {
  static const String _sessionsKey = 'study_sessions';
  static const String _lastStudyTimeKey = 'last_study_time';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Save a study session
  Future<void> saveSession(StudySession session) async {
    final sessions = await getSessions();
    sessions.add(session);
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _prefs.setString(_sessionsKey, jsonEncode(jsonList));
    await _prefs.setString(
      _lastStudyTimeKey,
      session.endTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
    );
  }

  // Get all study sessions
  Future<List<StudySession>> getSessions() async {
    final String? jsonString = _prefs.getString(_sessionsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => StudySession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Get last study time
  DateTime? getLastStudyTime() {
    final String? timeString = _prefs.getString(_lastStudyTimeKey);
    if (timeString == null) return null;
    return DateTime.parse(timeString);
  }

  // Get daily stats for the past N days
  Future<List<DailyStats>> getDailyStats(int days) async {
    final sessions = await getSessions();
    final now = DateTime.now();
    final stats = <DailyStats>[];

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final daySessions = sessions.where((s) {
        final sessionDate = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        return sessionDate.isAtSameMomentAs(date);
      }).toList();

      final totalMinutes = daySessions.fold<int>(
        0,
        (sum, s) => sum + s.durationMinutes,
      );

      stats.add(
        DailyStats(
          date: date,
          totalMinutes: totalMinutes,
          sessionCount: daySessions.length,
        ),
      );
    }

    return stats.reversed.toList();
  }

  // Get today's total study time in minutes
  Future<int> getTodayTotalMinutes() async {
    final sessions = await getSessions();
    final today = DateTime.now();
    final todaySessions = sessions.where((s) {
      return s.startTime.year == today.year &&
          s.startTime.month == today.month &&
          s.startTime.day == today.day;
    }).toList();

    return todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // Get total study time in minutes (all time)
  Future<int> getTotalMinutes() async {
    final sessions = await getSessions();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    await _prefs.remove(_sessionsKey);
    await _prefs.remove(_lastStudyTimeKey);
  }
}
