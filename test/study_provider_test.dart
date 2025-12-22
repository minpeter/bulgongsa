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

    test('study session improvement thresholds', () {
      // Improvement thresholds during study (in seconds):
      // 60s (1 min) -> veryAnxious (at least you started!)
      // 600s (10 min) -> anxious
      // 1800s (30 min) -> slightlyAnxious
      // 3600s (60 min) -> peaceful

      final improvementThresholds = <int, AnxietyLevel>{
        60: AnxietyLevel.veryAnxious, // 1 min
        600: AnxietyLevel.anxious, // 10 min
        1800: AnxietyLevel.slightlyAnxious, // 30 min
        3600: AnxietyLevel.peaceful, // 60 min
      };

      improvementThresholds.forEach((seconds, expectedLevel) {
        expect(
          _getPotentialLevelAfterStudying(seconds),
          equals(expectedLevel),
          reason:
              'After $seconds seconds of study, potential level should be ${expectedLevel.label}',
        );
      });
    });

    test('should not change state before 1 minute of studying', () async {
      // Given: First time user at slightlyAnxious
      final initialLevel = provider.anxietyLevel;

      // When: Start studying (0 seconds)
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

    test('anxiety level based on hours since last study (new thresholds)', () {
      // New thresholds for when NOT studying:
      // < 2 hours = peaceful
      // 2-24 hours = slightlyAnxious (same day)
      // 24-48 hours = anxious (1-2 days)
      // 48-168 hours = veryAnxious (2-7 days)
      // 168+ hours = panic (7+ days / a week)

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
        AnxietyLevelExtension.fromHoursSinceLastStudy(23),
        equals(AnxietyLevel.slightlyAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(24),
        equals(AnxietyLevel.anxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(47),
        equals(AnxietyLevel.anxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(48),
        equals(AnxietyLevel.veryAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(167),
        equals(AnxietyLevel.veryAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(168),
        equals(AnxietyLevel.panic),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(200),
        equals(AnxietyLevel.panic),
      );
    });
  });
}

/// Helper: Get potential anxiety level after studying for X seconds
/// This represents the best possible state after studying
AnxietyLevel _getPotentialLevelAfterStudying(int seconds) {
  if (seconds >= 3600) {
    return AnxietyLevel.peaceful; // 60 min+
  } else if (seconds >= 1800) {
    return AnxietyLevel.slightlyAnxious; // 30 min+
  } else if (seconds >= 600) {
    return AnxietyLevel.anxious; // 10 min+
  } else if (seconds >= 60) {
    return AnxietyLevel.veryAnxious; // 1 min+
  } else {
    return AnxietyLevel.panic; // No improvement yet
  }
}
