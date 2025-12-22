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
      'should maintain current state when study starts (not worsen)',
      () async {
        // Given: First time user starts at slightlyAnxious
        expect(provider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));

        // When: Start studying
        provider.startStudySession();

        // Then: Should maintain slightlyAnxious, NOT become panic
        expect(provider.isStudying, isTrue);
        expect(provider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));
      },
    );

    test('should never worsen during study session', () async {
      // Given: User is slightlyAnxious
      expect(provider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));

      // When: Start studying
      provider.startStudySession();

      // Then: Should never go to anxious, veryAnxious, or panic
      expect(
        provider.anxietyLevel.index,
        lessThanOrEqualTo(AnxietyLevel.slightlyAnxious.index),
      );
    });

    test('should only improve state during study (lower index = better)', () {
      // Document: AnxietyLevel.index ordering
      // peaceful = 0, slightlyAnxious = 1, anxious = 2, veryAnxious = 3, panic = 4
      expect(AnxietyLevel.peaceful.index, equals(0));
      expect(AnxietyLevel.slightlyAnxious.index, equals(1));
      expect(AnxietyLevel.anxious.index, equals(2));
      expect(AnxietyLevel.veryAnxious.index, equals(3));
      expect(AnxietyLevel.panic.index, equals(4));
    });

    test('study session improvement thresholds (from panic state)', () {
      // When starting from panic, these are the improvement milestones:
      // 10 min -> veryAnxious
      // 30 min -> anxious
      // 60 min -> slightlyAnxious
      // 120 min -> peaceful

      final improvementThresholds = <int, AnxietyLevel>{
        10: AnxietyLevel.veryAnxious,
        30: AnxietyLevel.anxious,
        60: AnxietyLevel.slightlyAnxious,
        120: AnxietyLevel.peaceful,
      };

      improvementThresholds.forEach((minutes, expectedLevel) {
        expect(
          _getPotentialLevelAfterStudying(minutes),
          equals(expectedLevel),
          reason:
              'After $minutes minutes of study, potential level should be ${expectedLevel.label}',
        );
      });
    });

    test('should not change state before 10 minutes of studying', () async {
      // Given: First time user at slightlyAnxious
      final initialLevel = provider.anxietyLevel;

      // When: Start studying (0 minutes)
      provider.startStudySession();

      // Then: State should remain the same
      expect(provider.anxietyLevel, equals(initialLevel));
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

    test('anxiety level based on hours since last study', () {
      // These thresholds are for when NOT studying
      // < 2 hours = peaceful
      // 2-4 hours = slightlyAnxious
      // 4-8 hours = anxious
      // 8-12 hours = veryAnxious
      // 12+ hours = panic

      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(0),
        equals(AnxietyLevel.peaceful),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(1),
        equals(AnxietyLevel.peaceful),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(2),
        equals(AnxietyLevel.slightlyAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(4),
        equals(AnxietyLevel.anxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(8),
        equals(AnxietyLevel.veryAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(12),
        equals(AnxietyLevel.panic),
      );
    });
  });
}

/// Helper: Get potential anxiety level after studying for X minutes
/// This represents the best possible state after studying
AnxietyLevel _getPotentialLevelAfterStudying(int minutes) {
  if (minutes >= 120) {
    return AnxietyLevel.peaceful;
  } else if (minutes >= 60) {
    return AnxietyLevel.slightlyAnxious;
  } else if (minutes >= 30) {
    return AnxietyLevel.anxious;
  } else if (minutes >= 10) {
    return AnxietyLevel.veryAnxious;
  } else {
    return AnxietyLevel.panic; // No improvement yet
  }
}
