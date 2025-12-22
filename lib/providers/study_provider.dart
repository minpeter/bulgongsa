import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/character_state.dart';
import '../models/study_session.dart';
import '../models/daily_stats.dart';
import '../services/storage_service.dart';

class StudyProvider extends ChangeNotifier {
  final StorageService _storage;

  // Loading state
  bool _isLoading = true;

  // Timer state
  bool _isStudying = false;
  DateTime? _sessionStartTime;
  Duration _currentSessionDuration = Duration.zero;
  Timer? _timer;

  // Character state - default to slightlyAnxious until loaded
  AnxietyLevel _anxietyLevel = AnxietyLevel.slightlyAnxious;
  DateTime? _lastStudyTime;
  Timer? _anxietyTimer;

  // Stats
  int _todaySeconds = 0;
  List<DailyStats> _weeklyStats = [];

  StudyProvider(this._storage) {
    _initializeState();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isStudying => _isStudying;
  Duration get currentSessionDuration => _currentSessionDuration;
  AnxietyLevel get anxietyLevel => _anxietyLevel;
  int get todaySeconds => _todaySeconds;
  int get todayMinutes => _todaySeconds ~/ 60;
  List<DailyStats> get weeklyStats => _weeklyStats;
  DateTime? get lastStudyTime => _lastStudyTime;

  Future<void> _initializeState() async {
    _lastStudyTime = _storage.getLastStudyTime();
    _todaySeconds = await _storage.getTodayTotalSeconds();
    _weeklyStats = await _storage.getDailyStats(7);
    _updateAnxietyLevel();
    _startAnxietyTimer();
    _isLoading = false;
    notifyListeners();
  }

  void _startAnxietyTimer() {
    _anxietyTimer?.cancel();
    _anxietyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isStudying) {
        _updateAnxietyLevel();
        notifyListeners();
      }
    });
  }

  void _updateAnxietyLevel() {
    if (_lastStudyTime == null) {
      // First time user - start at slightly anxious
      _anxietyLevel = AnxietyLevel.slightlyAnxious;
    } else {
      final hoursSinceLastStudy =
          DateTime.now().difference(_lastStudyTime!).inMinutes / 60.0;
      _anxietyLevel = AnxietyLevelExtension.fromHoursSinceLastStudy(
        hoursSinceLastStudy,
      );
    }
  }

  // Start a study session
  void startStudySession() {
    if (_isStudying) return;

    _isStudying = true;
    _sessionStartTime = DateTime.now();
    _currentSessionDuration = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentSessionDuration = DateTime.now().difference(_sessionStartTime!);
      _updateAnxietyLevelDuringStudy();
      notifyListeners();
    });

    notifyListeners();
  }

  void _updateAnxietyLevelDuringStudy() {
    // Calculate potential new level based on current session study time
    final currentSessionSeconds = _currentSessionDuration.inSeconds;
    AnxietyLevel potentialLevel;

    // Improvement thresholds (more lenient - any study helps!)
    if (currentSessionSeconds >= 3600) {
      // 1 hour+ = peaceful
      potentialLevel = AnxietyLevel.peaceful;
    } else if (currentSessionSeconds >= 1800) {
      // 30 min+ = slightly anxious
      potentialLevel = AnxietyLevel.slightlyAnxious;
    } else if (currentSessionSeconds >= 600) {
      // 10 min+ = anxious
      potentialLevel = AnxietyLevel.anxious;
    } else if (currentSessionSeconds >= 60) {
      // 1 min+ = very anxious (at least you started!)
      potentialLevel = AnxietyLevel.veryAnxious;
    } else {
      // Less than 1 minute - keep current state
      return;
    }

    // Only improve, never worsen (lower index = better state)
    if (potentialLevel.index < _anxietyLevel.index) {
      _anxietyLevel = potentialLevel;
    }
  }

  // Stop study session
  Future<void> stopStudySession() async {
    if (!_isStudying) return;

    _timer?.cancel();
    _isStudying = false;

    final endTime = DateTime.now();
    final durationSeconds = _currentSessionDuration.inSeconds;

    // Always save session even if less than 1 minute
    if (durationSeconds > 0) {
      final session = StudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStartTime!,
        endTime: endTime,
        durationSeconds: durationSeconds,
      );

      await _storage.saveSession(session);
      _lastStudyTime = endTime;
      _todaySeconds = await _storage.getTodayTotalSeconds();
      _weeklyStats = await _storage.getDailyStats(7);
    }

    _currentSessionDuration = Duration.zero;
    _sessionStartTime = null;

    notifyListeners();
  }

  // Refresh stats
  Future<void> refreshStats() async {
    _todaySeconds = await _storage.getTodayTotalSeconds();
    _weeklyStats = await _storage.getDailyStats(7);
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anxietyTimer?.cancel();
    super.dispose();
  }
}
