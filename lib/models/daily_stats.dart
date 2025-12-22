class DailyStats {
  final DateTime date;
  final int totalSeconds;
  final int sessionCount;

  DailyStats({
    required this.date,
    required this.totalSeconds,
    required this.sessionCount,
  });

  // Computed property for backward compatibility
  int get totalMinutes => totalSeconds ~/ 60;

  String get formattedDuration {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분 $seconds초';
    }
    return '$seconds초';
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalSeconds': totalSeconds,
      'sessionCount': sessionCount,
    };
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    int seconds;
    if (json.containsKey('totalSeconds')) {
      seconds = json['totalSeconds'] as int;
    } else if (json.containsKey('totalMinutes')) {
      seconds = (json['totalMinutes'] as int) * 60;
    } else {
      seconds = 0;
    }

    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      totalSeconds: seconds,
      sessionCount: json['sessionCount'] as int,
    );
  }
}
