import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/character_state.dart';
import '../models/study_session.dart';
import '../models/daily_stats.dart';
import '../services/storage_service.dart';

class StudyProvider extends ChangeNotifier {
  final StorageService _storage;

  // Timer state
  bool _isStudying = false;
  DateTime? _sessionStartTime;
  Duration _currentSessionDuration = Duration.zero;
  Timer? _timer;

  // Character state
  AnxietyLevel _anxietyLevel = AnxietyLevel.peaceful;
  DateTime? _lastStudyTime;
  Timer? _anxietyTimer;

  // Stats
  int _todaySeconds = 0;
  List<DailyStats> _weeklyStats = [];

  StudyProvider(this._storage) {
    _initializeState();
  }

  // Getters
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

    // Update anxiety level immediately when starting
    _updateAnxietyLevelDuringStudy();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentSessionDuration = DateTime.now().difference(_sessionStartTime!);
      _updateAnxietyLevelDuringStudy();
      notifyListeners();
    });

    notifyListeners();
  }

  void _updateAnxietyLevelDuringStudy() {
    // Calculate total study time including current session
    final currentSessionMinutes = _currentSessionDuration.inMinutes;
    final totalTodayMinutes = todayMinutes + currentSessionMinutes;

    // Anxiety decreases as you study more
    if (totalTodayMinutes >= 120) {
      _anxietyLevel = AnxietyLevel.peaceful;
    } else if (totalTodayMinutes >= 60) {
      _anxietyLevel = AnxietyLevel.slightlyAnxious;
    } else if (totalTodayMinutes >= 30) {
      _anxietyLevel = AnxietyLevel.anxious;
    } else if (totalTodayMinutes >= 10) {
      _anxietyLevel = AnxietyLevel.veryAnxious;
    } else {
      // Less than 10 minutes studied today - keep panic state
      _anxietyLevel = AnxietyLevel.panic;
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
