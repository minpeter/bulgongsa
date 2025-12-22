import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_anxiety_app/services/storage_service.dart';
import 'package:study_anxiety_app/models/study_session.dart';

void main() {
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
  });

  group('StorageService - Session Storage', () {
    test('should save and retrieve a session', () async {
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: DateTime(2025, 12, 22, 10, 5, 0),
        durationSeconds: 300,
      );

      await storageService.saveSession(session);
      final sessions = await storageService.getSessions();

      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals('test-1'));
      expect(sessions.first.durationSeconds, equals(300));
    });

    test('should save multiple sessions', () async {
      final session1 = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        durationSeconds: 60,
      );
      final session2 = StudySession(
        id: 'test-2',
        startTime: DateTime(2025, 12, 22, 11, 0, 0),
        durationSeconds: 120,
      );

      await storageService.saveSession(session1);
      await storageService.saveSession(session2);
      final sessions = await storageService.getSessions();

      expect(sessions.length, equals(2));
    });

    test('should update last study time when saving session', () async {
      final endTime = DateTime(2025, 12, 22, 10, 5, 0);
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: endTime,
        durationSeconds: 300,
      );

      await storageService.saveSession(session);
      final lastStudyTime = storageService.getLastStudyTime();

      expect(lastStudyTime, isNotNull);
      expect(lastStudyTime!.year, equals(2025));
      expect(lastStudyTime.month, equals(12));
      expect(lastStudyTime.day, equals(22));
    });
  });

  group('StorageService - Today Total Seconds', () {
    test('should return 0 for no sessions', () async {
      final totalSeconds = await storageService.getTodayTotalSeconds();
      expect(totalSeconds, equals(0));
    });

    test('should sum seconds for today sessions', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 10, 0, 0);

      final session1 = StudySession(
        id: 'today-1',
        startTime: todayStart,
        durationSeconds: 60,
      );
      final session2 = StudySession(
        id: 'today-2',
        startTime: todayStart.add(const Duration(hours: 1)),
        durationSeconds: 90,
      );

      await storageService.saveSession(session1);
      await storageService.saveSession(session2);

      final totalSeconds = await storageService.getTodayTotalSeconds();
      expect(totalSeconds, equals(150)); // 60 + 90
    });

    test('should not count yesterday sessions', () async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0, 0);
      final todayStart = DateTime(now.year, now.month, now.day, 10, 0, 0);

      final yesterdaySession = StudySession(
        id: 'yesterday-1',
        startTime: yesterday,
        durationSeconds: 1000,
      );
      final todaySession = StudySession(
        id: 'today-1',
        startTime: todayStart,
        durationSeconds: 60,
      );

      await storageService.saveSession(yesterdaySession);
      await storageService.saveSession(todaySession);

      final totalSeconds = await storageService.getTodayTotalSeconds();
      expect(totalSeconds, equals(60)); // Only today's session
    });

    test('should handle sessions with less than 1 minute', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 10, 0, 0);

      final shortSession = StudySession(
        id: 'short-1',
        startTime: todayStart,
        durationSeconds: 30, // 30 seconds
      );

      await storageService.saveSession(shortSession);

      final totalSeconds = await storageService.getTodayTotalSeconds();
      expect(totalSeconds, equals(30));

      final totalMinutes = await storageService.getTodayTotalMinutes();
      expect(totalMinutes, equals(0)); // 30 ~/ 60 = 0
    });
  });

  group('StorageService - Daily Stats', () {
    test('should return stats for specified days', () async {
      final stats = await storageService.getDailyStats(7);
      expect(stats.length, equals(7));
    });

    test('should aggregate sessions by day', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 10, 0, 0);

      // Add multiple sessions for today
      await storageService.saveSession(
        StudySession(id: 'today-1', startTime: todayStart, durationSeconds: 60),
      );
      await storageService.saveSession(
        StudySession(
          id: 'today-2',
          startTime: todayStart.add(const Duration(hours: 1)),
          durationSeconds: 120,
        ),
      );

      final stats = await storageService.getDailyStats(7);
      final todayStats = stats.last; // Today should be last in the list

      expect(todayStats.totalSeconds, equals(180)); // 60 + 120
      expect(todayStats.sessionCount, equals(2));
    });

    test(
      'should include sessions with less than 1 minute in daily stats',
      () async {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day, 10, 0, 0);

        await storageService.saveSession(
          StudySession(
            id: 'short-1',
            startTime: todayStart,
            durationSeconds: 45, // 45 seconds
          ),
        );

        final stats = await storageService.getDailyStats(1);

        expect(stats.length, equals(1));
        expect(stats.first.totalSeconds, equals(45));
        expect(stats.first.sessionCount, equals(1));
      },
    );
  });

  group('StorageService - Last Study Time', () {
    test('should return null when no sessions', () {
      final lastStudyTime = storageService.getLastStudyTime();
      expect(lastStudyTime, isNull);
    });

    test('should return last study time after saving session', () async {
      final endTime = DateTime(2025, 12, 22, 15, 30, 0);
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 15, 0, 0),
        endTime: endTime,
        durationSeconds: 1800,
      );

      await storageService.saveSession(session);
      final lastStudyTime = storageService.getLastStudyTime();

      expect(lastStudyTime, equals(endTime));
    });
  });

  group('StorageService - Clear Data', () {
    test('should clear all data', () async {
      // Add some data first
      await storageService.saveSession(
        StudySession(
          id: 'test-1',
          startTime: DateTime.now(),
          durationSeconds: 60,
        ),
      );

      // Clear
      await storageService.clearAll();

      // Verify cleared
      final sessions = await storageService.getSessions();
      final lastStudyTime = storageService.getLastStudyTime();

      expect(sessions.length, equals(0));
      expect(lastStudyTime, isNull);
    });
  });

  group('StorageService - Total Seconds', () {
    test('should calculate total seconds across all sessions', () async {
      final now = DateTime.now();

      await storageService.saveSession(
        StudySession(
          id: 'session-1',
          startTime: now.subtract(const Duration(days: 2)),
          durationSeconds: 100,
        ),
      );
      await storageService.saveSession(
        StudySession(
          id: 'session-2',
          startTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 200,
        ),
      );
      await storageService.saveSession(
        StudySession(id: 'session-3', startTime: now, durationSeconds: 300),
      );

      final totalSeconds = await storageService.getTotalSeconds();
      expect(totalSeconds, equals(600)); // 100 + 200 + 300
    });
  });
}
