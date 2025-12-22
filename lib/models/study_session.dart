class StudySession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;

  StudySession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
  });

  // Computed property for backward compatibility
  int get durationMinutes => durationSeconds ~/ 60;

  StudySession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
  }) {
    return StudySession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      // Keep durationMinutes for backward compatibility when reading old data
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    // Support both old (durationMinutes) and new (durationSeconds) format
    int seconds;
    if (json.containsKey('durationSeconds')) {
      seconds = json['durationSeconds'] as int;
    } else if (json.containsKey('durationMinutes')) {
      seconds = (json['durationMinutes'] as int) * 60;
    } else {
      seconds = 0;
    }

    return StudySession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationSeconds: seconds,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, startTime: $startTime, endTime: $endTime, durationSeconds: $durationSeconds)';
  }
}
