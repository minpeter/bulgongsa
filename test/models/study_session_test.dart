import 'package:flutter_test/flutter_test.dart';
import 'package:study_anxiety_app/models/study_session.dart';

void main() {
  group('StudySession - Seconds Storage', () {
    test('should store duration in seconds', () {
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: DateTime(2025, 12, 22, 10, 0, 30),
        durationSeconds: 30,
      );

      expect(session.durationSeconds, equals(30));
    });

    test('should compute durationMinutes from durationSeconds', () {
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        durationSeconds: 150, // 2 minutes 30 seconds
      );

      expect(session.durationMinutes, equals(2)); // 150 ~/ 60 = 2
    });

    test('should serialize to JSON with durationSeconds', () {
      final session = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: DateTime(2025, 12, 22, 10, 5, 30),
        durationSeconds: 330,
      );

      final json = session.toJson();

      expect(json['durationSeconds'], equals(330));
      expect(json['id'], equals('test-1'));
      expect(json.containsKey('startTime'), isTrue);
      expect(json.containsKey('endTime'), isTrue);
    });

    test('should deserialize from JSON with durationSeconds', () {
      final json = {
        'id': 'test-1',
        'startTime': '2025-12-22T10:00:00.000',
        'endTime': '2025-12-22T10:05:30.000',
        'durationSeconds': 330,
      };

      final session = StudySession.fromJson(json);

      expect(session.id, equals('test-1'));
      expect(session.durationSeconds, equals(330));
      expect(session.durationMinutes, equals(5));
    });

    test(
      'should handle legacy JSON with durationMinutes (backward compatibility)',
      () {
        final legacyJson = {
          'id': 'legacy-1',
          'startTime': '2025-12-22T10:00:00.000',
          'endTime': '2025-12-22T10:30:00.000',
          'durationMinutes': 30, // Old format
        };

        final session = StudySession.fromJson(legacyJson);

        // Should convert minutes to seconds
        expect(session.durationSeconds, equals(1800)); // 30 * 60
        expect(session.durationMinutes, equals(30));
      },
    );

    test(
      'should prefer durationSeconds over durationMinutes if both present',
      () {
        final json = {
          'id': 'test-1',
          'startTime': '2025-12-22T10:00:00.000',
          'durationSeconds': 90,
          'durationMinutes': 5, // Should be ignored
        };

        final session = StudySession.fromJson(json);

        expect(session.durationSeconds, equals(90));
        expect(session.durationMinutes, equals(1)); // 90 ~/ 60 = 1
      },
    );

    test('should default to 0 seconds if no duration field present', () {
      final json = {'id': 'test-1', 'startTime': '2025-12-22T10:00:00.000'};

      final session = StudySession.fromJson(json);

      expect(session.durationSeconds, equals(0));
    });

    test('should handle null endTime', () {
      final json = {
        'id': 'test-1',
        'startTime': '2025-12-22T10:00:00.000',
        'endTime': null,
        'durationSeconds': 60,
      };

      final session = StudySession.fromJson(json);

      expect(session.endTime, isNull);
      expect(session.durationSeconds, equals(60));
    });
  });

  group('StudySession - copyWith', () {
    test('should copy with new durationSeconds', () {
      final original = StudySession(
        id: 'test-1',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        durationSeconds: 60,
      );

      final copied = original.copyWith(durationSeconds: 120);

      expect(copied.id, equals('test-1'));
      expect(copied.durationSeconds, equals(120));
      expect(original.durationSeconds, equals(60)); // Original unchanged
    });
  });

  group('StudySession - Short Duration Recording', () {
    test('should correctly store sessions less than 1 minute', () {
      final session = StudySession(
        id: 'short-session',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: DateTime(2025, 12, 22, 10, 0, 45),
        durationSeconds: 45,
      );

      expect(session.durationSeconds, equals(45));
      expect(session.durationMinutes, equals(0)); // Less than 1 minute
    });

    test('should correctly store sessions of exactly 1 second', () {
      final session = StudySession(
        id: 'tiny-session',
        startTime: DateTime(2025, 12, 22, 10, 0, 0),
        endTime: DateTime(2025, 12, 22, 10, 0, 1),
        durationSeconds: 1,
      );

      expect(session.durationSeconds, equals(1));
      expect(session.durationMinutes, equals(0));

      // Should serialize and deserialize correctly
      final json = session.toJson();
      final restored = StudySession.fromJson(json);
      expect(restored.durationSeconds, equals(1));
    });
  });
}
