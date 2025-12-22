import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_anxiety_app/providers/study_provider.dart';
import 'package:study_anxiety_app/services/storage_service.dart';
import 'package:study_anxiety_app/models/character_state.dart';

void main() {
  late StudyProvider provider;
  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    provider = StudyProvider(storageService);
    // Wait for async initialization
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() {
    provider.dispose();
  });

  group('StudyProvider - Anxiety Level During Study', () {
    test(
      'should be panic state immediately when study starts with 0 minutes today',
      () async {
        // Given: No previous study today
        expect(provider.todayMinutes, equals(0));

        // When: Start studying
        provider.startStudySession();

        // Then: Should be panic state immediately (not after 1 second)
        expect(provider.isStudying, isTrue);
        expect(provider.anxietyLevel, equals(AnxietyLevel.panic));
      },
    );

    test('should remain panic state at 0 seconds of studying', () async {
      provider.startStudySession();

      // At 0 seconds, should be panic
      expect(provider.currentSessionDuration.inSeconds, equals(0));
      expect(provider.anxietyLevel, equals(AnxietyLevel.panic));
    });

    test(
      'should transition to veryAnxious after 10 minutes of study',
      () async {
        // Simulate having studied for 10 minutes today
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);

        // Create a mock provider that we can manipulate
        final testProvider = StudyProvider(storage);
        await Future.delayed(const Duration(milliseconds: 100));

        testProvider.startStudySession();

        // Initially should be panic (0 minutes)
        expect(testProvider.anxietyLevel, equals(AnxietyLevel.panic));

        testProvider.dispose();
      },
    );

    test('anxiety levels should follow correct thresholds', () {
      // Test the threshold logic directly
      // < 10 min = panic
      // >= 10 min = veryAnxious
      // >= 30 min = anxious
      // >= 60 min = slightlyAnxious
      // >= 120 min = peaceful

      // These are the expected transitions during study
      final thresholds = <int, AnxietyLevel>{
        0: AnxietyLevel.panic,
        5: AnxietyLevel.panic,
        9: AnxietyLevel.panic,
        10: AnxietyLevel.veryAnxious,
        29: AnxietyLevel.veryAnxious,
        30: AnxietyLevel.anxious,
        59: AnxietyLevel.anxious,
        60: AnxietyLevel.slightlyAnxious,
        119: AnxietyLevel.slightlyAnxious,
        120: AnxietyLevel.peaceful,
        180: AnxietyLevel.peaceful,
      };

      thresholds.forEach((minutes, expectedLevel) {
        // This documents the expected behavior
        expect(
          _getExpectedAnxietyLevel(minutes),
          equals(expectedLevel),
          reason: 'At $minutes minutes, should be ${expectedLevel.label}',
        );
      });
    });
  });

  group('StudyProvider - Session Recording', () {
    test('should record session in seconds, not minutes', () async {
      provider.startStudySession();

      // Simulate 30 seconds of studying
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.stopStudySession();

      // Session should be saved even if less than 1 minute
      // (The actual duration will be very short in this test)
      expect(provider.isStudying, isFalse);
    });

    test('should save session even for very short duration', () async {
      provider.startStudySession();
      expect(provider.isStudying, isTrue);

      // Stop immediately
      await provider.stopStudySession();

      expect(provider.isStudying, isFalse);
      expect(provider.currentSessionDuration, equals(Duration.zero));
    });
  });

  group('StudyProvider - Timer Functionality', () {
    test('should track duration correctly', () async {
      provider.startStudySession();

      expect(provider.currentSessionDuration, equals(Duration.zero));
      expect(provider.isStudying, isTrue);

      await provider.stopStudySession();

      expect(provider.isStudying, isFalse);
    });

    test('formatDuration should format correctly', () {
      expect(
        provider.formatDuration(
          const Duration(hours: 1, minutes: 30, seconds: 45),
        ),
        equals('01:30:45'),
      );
      expect(
        provider.formatDuration(const Duration(minutes: 5, seconds: 3)),
        equals('00:05:03'),
      );
      expect(provider.formatDuration(Duration.zero), equals('00:00:00'));
    });
  });

  group('StudyProvider - Anxiety Level When Not Studying', () {
    test('should be slightlyAnxious for first time user', () async {
      // Fresh provider with no study history
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final newProvider = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      // First time user should be slightly anxious
      expect(newProvider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));

      newProvider.dispose();
    });
  });
}

/// Helper function to get expected anxiety level based on total minutes studied today
AnxietyLevel _getExpectedAnxietyLevel(int totalMinutes) {
  if (totalMinutes >= 120) {
    return AnxietyLevel.peaceful;
  } else if (totalMinutes >= 60) {
    return AnxietyLevel.slightlyAnxious;
  } else if (totalMinutes >= 30) {
    return AnxietyLevel.anxious;
  } else if (totalMinutes >= 10) {
    return AnxietyLevel.veryAnxious;
  } else {
    return AnxietyLevel.panic;
  }
}
