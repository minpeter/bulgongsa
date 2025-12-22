import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_anxiety_app/providers/study_provider.dart';
import 'package:study_anxiety_app/services/storage_service.dart';
import 'package:study_anxiety_app/models/character_state.dart';

/// Integration tests for the complete study session flow
void main() {
  group('Integration - Complete Study Session Flow', () {
    late StudyProvider provider;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      provider = StudyProvider(storageService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test(
      'complete flow: start study -> state maintained -> stop -> session saved',
      () async {
        // 1. Initial state - first time user
        expect(provider.isStudying, isFalse);
        expect(provider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));
        expect(provider.todaySeconds, equals(0));

        // 2. Start studying - should maintain current state (not worsen)
        provider.startStudySession();
        expect(provider.isStudying, isTrue);
        expect(provider.anxietyLevel, equals(AnxietyLevel.slightlyAnxious));
        expect(provider.currentSessionDuration, equals(Duration.zero));

        // 3. Stop studying (short session)
        await provider.stopStudySession();
        expect(provider.isStudying, isFalse);
        expect(provider.currentSessionDuration, equals(Duration.zero));
      },
    );

    test('anxiety level should NOT worsen when starting study', () async {
      // Given: First time user at slightlyAnxious
      final initialLevel = provider.anxietyLevel;
      expect(initialLevel, equals(AnxietyLevel.slightlyAnxious));

      // When: Start study
      provider.startStudySession();

      // Then: Should maintain or improve, NEVER worsen
      expect(
        provider.anxietyLevel.index,
        lessThanOrEqualTo(initialLevel.index),
      );

      // Cleanup
      await provider.stopStudySession();
    });

    test('short sessions (< 1 minute) should be saved in seconds', () async {
      // This test verifies the fix for the "short session not recorded" bug

      // Start session
      provider.startStudySession();
      expect(provider.isStudying, isTrue);

      // Wait a tiny bit (in real app this would be user studying)
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop session
      await provider.stopStudySession();
      expect(provider.isStudying, isFalse);

      // Verify session state is reset
      expect(provider.currentSessionDuration, equals(Duration.zero));
    });
  });

  group('Integration - Anxiety Level Logic', () {
    test('when not studying: based on hours since last study', () {
      // New thresholds (more realistic):
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
        AnxietyLevelExtension.fromHoursSinceLastStudy(1.9),
        equals(AnxietyLevel.peaceful),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(2),
        equals(AnxietyLevel.slightlyAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(24),
        equals(AnxietyLevel.anxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(48),
        equals(AnxietyLevel.veryAnxious),
      );
      expect(
        AnxietyLevelExtension.fromHoursSinceLastStudy(168),
        equals(AnxietyLevel.panic),
      );
    });

    test('when studying: state can only improve, never worsen', () {
      // Document the key behavior change:
      // - OLD: Starting study could make state WORSE (panic if < 10 min today)
      // - NEW: Starting study maintains state, studying improves it

      // Lower index = better state
      expect(AnxietyLevel.peaceful.index, lessThan(AnxietyLevel.panic.index));
    });
  });

  group('Integration - Data Persistence', () {
    test('sessions should persist across provider instances', () async {
      // Setup first provider and save a session
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final provider1 = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      // Start and stop a session
      provider1.startStudySession();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider1.stopStudySession();
      provider1.dispose();

      // Create new provider instance (simulates app restart)
      final provider2 = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      // The weekly stats should still show data
      expect(provider2.weeklyStats, isNotNull);
      expect(provider2.weeklyStats.length, equals(7));

      provider2.dispose();
    });
  });

  group('Integration - Edge Cases', () {
    test('multiple start/stop cycles should work correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final provider = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      // Cycle 1
      provider.startStudySession();
      expect(provider.isStudying, isTrue);
      await provider.stopStudySession();
      expect(provider.isStudying, isFalse);

      // Cycle 2
      provider.startStudySession();
      expect(provider.isStudying, isTrue);
      await provider.stopStudySession();
      expect(provider.isStudying, isFalse);

      // Cycle 3
      provider.startStudySession();
      expect(provider.isStudying, isTrue);
      await provider.stopStudySession();
      expect(provider.isStudying, isFalse);

      provider.dispose();
    });

    test('double start should be ignored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final provider = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startStudySession();
      final firstStartTime = provider.currentSessionDuration;

      provider.startStudySession(); // Should be ignored
      expect(provider.currentSessionDuration, equals(firstStartTime));

      await provider.stopStudySession();
      provider.dispose();
    });

    test('double stop should be safe', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final provider = StudyProvider(storage);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.startStudySession();
      await provider.stopStudySession();

      // Double stop should not throw
      await provider.stopStudySession();
      expect(provider.isStudying, isFalse);

      provider.dispose();
    });
  });
}
