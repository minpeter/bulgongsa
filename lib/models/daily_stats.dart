class DailyStats {
  final DateTime date;
  final int totalMinutes;
  final int sessionCount;

  DailyStats({
    required this.date,
    required this.totalMinutes,
    required this.sessionCount,
  });

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalMinutes': totalMinutes,
      'sessionCount': sessionCount,
    };
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      totalMinutes: json['totalMinutes'] as int,
      sessionCount: json['sessionCount'] as int,
    );
  }
}
