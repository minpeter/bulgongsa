/// Character anxiety states based on study activity
enum AnxietyLevel {
  peaceful, // Just finished studying or within 2 hours
  slightlyAnxious, // 2-4 hours since last study
  anxious, // 4-8 hours since last study
  veryAnxious, // 8-12 hours since last study
  panic, // 12+ hours since last study
}

extension AnxietyLevelExtension on AnxietyLevel {
  String get imagePath {
    switch (this) {
      case AnxietyLevel.peaceful:
        return 'assets/images/characters/character_peaceful.png';
      case AnxietyLevel.slightlyAnxious:
        return 'assets/images/characters/character_slightly_anxious.png';
      case AnxietyLevel.anxious:
        return 'assets/images/characters/character_anxious.png';
      case AnxietyLevel.veryAnxious:
        return 'assets/images/characters/character_very_anxious.png';
      case AnxietyLevel.panic:
        return 'assets/images/characters/character_panic.png';
    }
  }

  String get emoji {
    switch (this) {
      case AnxietyLevel.peaceful:
        return '😌';
      case AnxietyLevel.slightlyAnxious:
        return '😅';
      case AnxietyLevel.anxious:
        return '😰';
      case AnxietyLevel.veryAnxious:
        return '😱';
      case AnxietyLevel.panic:
        return '🤯';
    }
  }

  String get label {
    switch (this) {
      case AnxietyLevel.peaceful:
        return '평온';
      case AnxietyLevel.slightlyAnxious:
        return '약간 불안';
      case AnxietyLevel.anxious:
        return '불안';
      case AnxietyLevel.veryAnxious:
        return '매우 불안';
      case AnxietyLevel.panic:
        return '패닉';
    }
  }

  String get message {
    switch (this) {
      case AnxietyLevel.peaceful:
        return '공부 잘 했어요! 편안해요 ☺️';
      case AnxietyLevel.slightlyAnxious:
        return '슬슬 공부해야 할 것 같은데...';
      case AnxietyLevel.anxious:
        return '공부 안 한지 좀 됐어요... 불안해요 😥';
      case AnxietyLevel.veryAnxious:
        return '공부 안 하면 큰일 날 것 같아요!! 😭';
      case AnxietyLevel.panic:
        return '으아아아!! 당장 공부해야 해요!!! 🆘';
    }
  }

  /// Calculate anxiety level based on hours since last study
  static AnxietyLevel fromHoursSinceLastStudy(double hours) {
    if (hours < 2) {
      return AnxietyLevel.peaceful;
    } else if (hours < 4) {
      return AnxietyLevel.slightlyAnxious;
    } else if (hours < 8) {
      return AnxietyLevel.anxious;
    } else if (hours < 12) {
      return AnxietyLevel.veryAnxious;
    } else {
      return AnxietyLevel.panic;
    }
  }
}
