import 'package:flutter_test/flutter_test.dart';
import 'package:study_anxiety_app/models/daily_stats.dart';

void main() {
  group('DailyStats - Seconds Storage', () {
    test('should store duration in seconds', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 3661, // 1 hour, 1 minute, 1 second
        sessionCount: 3,
      );

      expect(stats.totalSeconds, equals(3661));
    });

    test('should compute totalMinutes from totalSeconds', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 3661, // 1 hour, 1 minute, 1 second
        sessionCount: 1,
      );

      expect(stats.totalMinutes, equals(61)); // 3661 ~/ 60 = 61
    });
  });

  group('DailyStats - formattedDuration', () {
    test('should format hours and minutes correctly', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 5400, // 1.5 hours = 90 minutes
        sessionCount: 1,
      );

      expect(stats.formattedDuration, equals('1시간 30분'));
    });

    test('should format minutes and seconds when no hours', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 150, // 2 minutes 30 seconds
        sessionCount: 1,
      );

      expect(stats.formattedDuration, equals('2분 30초'));
    });

    test('should format only seconds when less than 1 minute', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 45,
        sessionCount: 1,
      );

      expect(stats.formattedDuration, equals('45초'));
    });

    test('should show 0초 for zero seconds', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 0,
        sessionCount: 0,
      );

      expect(stats.formattedDuration, equals('0초'));
    });

    test('should format exactly 1 hour correctly', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 3600,
        sessionCount: 1,
      );

      expect(stats.formattedDuration, equals('1시간 0분'));
    });

    test('should format exactly 1 minute correctly', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 60,
        sessionCount: 1,
      );

      expect(stats.formattedDuration, equals('1분 0초'));
    });
  });

  group('DailyStats - JSON Serialization', () {
    test('should serialize to JSON with totalSeconds', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 1800,
        sessionCount: 5,
      );

      final json = stats.toJson();

      expect(json['totalSeconds'], equals(1800));
      expect(json['sessionCount'], equals(5));
      expect(json.containsKey('date'), isTrue);
    });

    test('should deserialize from JSON with totalSeconds', () {
      final json = {
        'date': '2025-12-22T00:00:00.000',
        'totalSeconds': 1800,
        'sessionCount': 5,
      };

      final stats = DailyStats.fromJson(json);

      expect(stats.totalSeconds, equals(1800));
      expect(stats.sessionCount, equals(5));
      expect(stats.date.year, equals(2025));
      expect(stats.date.month, equals(12));
      expect(stats.date.day, equals(22));
    });

    test(
      'should handle legacy JSON with totalMinutes (backward compatibility)',
      () {
        final legacyJson = {
          'date': '2025-12-22T00:00:00.000',
          'totalMinutes': 30,
          'sessionCount': 3,
        };

        final stats = DailyStats.fromJson(legacyJson);

        // Should convert minutes to seconds
        expect(stats.totalSeconds, equals(1800)); // 30 * 60
        expect(stats.totalMinutes, equals(30));
      },
    );

    test('should prefer totalSeconds over totalMinutes if both present', () {
      final json = {
        'date': '2025-12-22T00:00:00.000',
        'totalSeconds': 90,
        'totalMinutes': 30, // Should be ignored
        'sessionCount': 1,
      };

      final stats = DailyStats.fromJson(json);

      expect(stats.totalSeconds, equals(90));
      expect(stats.totalMinutes, equals(1)); // 90 ~/ 60 = 1
    });

    test('should default to 0 if no duration field present', () {
      final json = {'date': '2025-12-22T00:00:00.000', 'sessionCount': 0};

      final stats = DailyStats.fromJson(json);

      expect(stats.totalSeconds, equals(0));
    });
  });

  group('DailyStats - Edge Cases', () {
    test('should handle very large durations', () {
      // 24 hours in seconds
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 86400,
        sessionCount: 10,
      );

      expect(stats.totalMinutes, equals(1440));
      expect(stats.formattedDuration, equals('24시간 0분'));
    });

    test('should handle single second duration', () {
      final stats = DailyStats(
        date: DateTime(2025, 12, 22),
        totalSeconds: 1,
        sessionCount: 1,
      );

      expect(stats.totalMinutes, equals(0));
      expect(stats.formattedDuration, equals('1초'));
    });
  });
}
