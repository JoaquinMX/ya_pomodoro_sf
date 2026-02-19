enum LocaleMode { system, en, es419 }

extension LocaleModeStorage on LocaleMode {
  String get storageValue {
    switch (this) {
      case LocaleMode.system:
        return 'system';
      case LocaleMode.en:
        return 'en';
      case LocaleMode.es419:
        return 'es_419';
    }
  }

  static LocaleMode fromStorage(String? value) {
    switch (value) {
      case 'en':
        return LocaleMode.en;
      case 'es_419':
        return LocaleMode.es419;
      default:
        return LocaleMode.system;
    }
  }
}

class PomodoroSettings {
  static const int minDurationMinutes = 1;
  static const int maxDurationMinutes = 120;

  static const int defaultPomodoroMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;

  const PomodoroSettings({
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.showCycleProgress,
    required this.localeMode,
  });

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool showCycleProgress;
  final LocaleMode localeMode;

  factory PomodoroSettings.defaults() {
    return const PomodoroSettings(
      pomodoroMinutes: defaultPomodoroMinutes,
      shortBreakMinutes: defaultShortBreakMinutes,
      longBreakMinutes: defaultLongBreakMinutes,
      showCycleProgress: true,
      localeMode: LocaleMode.system,
    );
  }

  PomodoroSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? showCycleProgress,
    LocaleMode? localeMode,
  }) {
    return PomodoroSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      showCycleProgress: showCycleProgress ?? this.showCycleProgress,
      localeMode: localeMode ?? this.localeMode,
    );
  }

  bool get isValid =>
      isDurationValid(pomodoroMinutes) &&
      isDurationValid(shortBreakMinutes) &&
      isDurationValid(longBreakMinutes);

  static bool isDurationValid(int value) {
    return value >= minDurationMinutes && value <= maxDurationMinutes;
  }

  Map<String, Object> toStorageMap() {
    return <String, Object>{
      'pomodoroMinutes': pomodoroMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'showCycleProgress': showCycleProgress,
      'localeMode': localeMode.storageValue,
    };
  }

  factory PomodoroSettings.fromStorageMap(Map<String, Object?> values) {
    final PomodoroSettings defaults = PomodoroSettings.defaults();

    int sanitizeDuration(Object? raw, int fallback) {
      if (raw is int && isDurationValid(raw)) {
        return raw;
      }
      return fallback;
    }

    final int pomodoro = sanitizeDuration(
      values['pomodoroMinutes'],
      defaults.pomodoroMinutes,
    );
    final int shortBreak = sanitizeDuration(
      values['shortBreakMinutes'],
      defaults.shortBreakMinutes,
    );
    final int longBreak = sanitizeDuration(
      values['longBreakMinutes'],
      defaults.longBreakMinutes,
    );

    return PomodoroSettings(
      pomodoroMinutes: pomodoro,
      shortBreakMinutes: shortBreak,
      longBreakMinutes: longBreak,
      showCycleProgress: values['showCycleProgress'] is bool
          ? values['showCycleProgress']! as bool
          : defaults.showCycleProgress,
      localeMode: LocaleModeStorage.fromStorage(
        values['localeMode'] as String?,
      ),
    );
  }
}
