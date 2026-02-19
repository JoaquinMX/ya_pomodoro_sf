import '../../settings/domain/pomodoro_settings.dart';

enum TimerPhase { pomodoro, shortBreak, longBreak }

enum TimerRunState { idle, running, paused }

extension TimerPhaseStorage on TimerPhase {
  String get storageValue {
    switch (this) {
      case TimerPhase.pomodoro:
        return 'pomodoro';
      case TimerPhase.shortBreak:
        return 'shortBreak';
      case TimerPhase.longBreak:
        return 'longBreak';
    }
  }

  int durationSeconds(PomodoroSettings settings) {
    switch (this) {
      case TimerPhase.pomodoro:
        return settings.pomodoroMinutes * 60;
      case TimerPhase.shortBreak:
        return settings.shortBreakMinutes * 60;
      case TimerPhase.longBreak:
        return settings.longBreakMinutes * 60;
    }
  }

  static TimerPhase fromStorage(String? value) {
    switch (value) {
      case 'shortBreak':
        return TimerPhase.shortBreak;
      case 'longBreak':
        return TimerPhase.longBreak;
      default:
        return TimerPhase.pomodoro;
    }
  }
}

extension TimerRunStateStorage on TimerRunState {
  String get storageValue {
    switch (this) {
      case TimerRunState.idle:
        return 'idle';
      case TimerRunState.running:
        return 'running';
      case TimerRunState.paused:
        return 'paused';
    }
  }

  static TimerRunState fromStorage(String? value) {
    switch (value) {
      case 'running':
        return TimerRunState.running;
      case 'paused':
        return TimerRunState.paused;
      default:
        return TimerRunState.idle;
    }
  }
}

class TimerSessionState {
  const TimerSessionState({
    required this.phase,
    required this.runState,
    required this.remainingSeconds,
    required this.completedPomodorosInCycle,
    this.phaseStartedAtUtc,
    this.phaseEndsAtUtc,
  });

  final TimerPhase phase;
  final TimerRunState runState;
  final int remainingSeconds;
  final int completedPomodorosInCycle;
  final DateTime? phaseStartedAtUtc;
  final DateTime? phaseEndsAtUtc;

  factory TimerSessionState.idle(PomodoroSettings settings) {
    return TimerSessionState(
      phase: TimerPhase.pomodoro,
      runState: TimerRunState.idle,
      remainingSeconds: TimerPhase.pomodoro.durationSeconds(settings),
      completedPomodorosInCycle: 0,
    );
  }

  bool get isRunning => runState == TimerRunState.running;
  bool get isPaused => runState == TimerRunState.paused;
  bool get isIdle => runState == TimerRunState.idle;

  TimerSessionState copyWith({
    TimerPhase? phase,
    TimerRunState? runState,
    int? remainingSeconds,
    int? completedPomodorosInCycle,
    DateTime? phaseStartedAtUtc,
    DateTime? phaseEndsAtUtc,
    bool clearPhaseStartedAtUtc = false,
    bool clearPhaseEndsAtUtc = false,
  }) {
    return TimerSessionState(
      phase: phase ?? this.phase,
      runState: runState ?? this.runState,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedPomodorosInCycle:
          completedPomodorosInCycle ?? this.completedPomodorosInCycle,
      phaseStartedAtUtc: clearPhaseStartedAtUtc
          ? null
          : phaseStartedAtUtc ?? this.phaseStartedAtUtc,
      phaseEndsAtUtc: clearPhaseEndsAtUtc
          ? null
          : phaseEndsAtUtc ?? this.phaseEndsAtUtc,
    );
  }

  Map<String, Object> toStorageMap() {
    return <String, Object>{
      'phase': phase.storageValue,
      'runState': runState.storageValue,
      'remainingSeconds': remainingSeconds,
      'completedPomodorosInCycle': completedPomodorosInCycle,
      'phaseStartedAtUtc': phaseStartedAtUtc?.toIso8601String() ?? '',
      'phaseEndsAtUtc': phaseEndsAtUtc?.toIso8601String() ?? '',
    };
  }

  factory TimerSessionState.fromStorageMap(Map<String, Object?> values) {
    DateTime? parseDate(Object? value) {
      if (value is! String || value.isEmpty) {
        return null;
      }
      return DateTime.tryParse(value)?.toUtc();
    }

    final int remaining = values['remainingSeconds'] is int
        ? values['remainingSeconds']! as int
        : PomodoroSettings.defaultPomodoroMinutes * 60;

    final int cycle = values['completedPomodorosInCycle'] is int
        ? values['completedPomodorosInCycle']! as int
        : 0;

    return TimerSessionState(
      phase: TimerPhaseStorage.fromStorage(values['phase'] as String?),
      runState: TimerRunStateStorage.fromStorage(values['runState'] as String?),
      remainingSeconds: remaining > 0 ? remaining : 1,
      completedPomodorosInCycle: cycle.clamp(0, 4),
      phaseStartedAtUtc: parseDate(values['phaseStartedAtUtc']),
      phaseEndsAtUtc: parseDate(values['phaseEndsAtUtc']),
    );
  }
}
