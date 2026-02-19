import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/domain/pomodoro_settings.dart';
import '../domain/session_repository.dart';
import '../domain/timer_models.dart';
import '../../../services/audio/audio_cue_service.dart';
import '../../../services/notifications/notification_service.dart';

class TimerController extends StateNotifier<TimerSessionState> {
  TimerController({
    required PomodoroSettings initialSettings,
    required TimerSessionState? initialSession,
    required SessionRepository sessionRepository,
    required NotificationService notificationService,
    required AudioCueService audioCueService,
    required DateTime Function() now,
  }) : _settings = initialSettings,
       _initialSession = initialSession,
       _sessionRepository = sessionRepository,
       _notificationService = notificationService,
       _audioCueService = audioCueService,
       _now = now,
       super(TimerSessionState.idle(initialSettings)) {
    state = _restoreSnapshot(
      snapshot: initialSession,
      settings: initialSettings,
      now: _now(),
    );

    if (state.isRunning) {
      _startTicker();
      unawaited(_scheduleNotificationForCurrentPhase());
    }
  }

  final SessionRepository _sessionRepository;
  final NotificationService _notificationService;
  final AudioCueService _audioCueService;
  final DateTime Function() _now;

  final TimerSessionState? _initialSession;

  PomodoroSettings _settings;
  Timer? _ticker;
  bool _didRequestNotificationPermission = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> restoreOnLaunch() async {
    final TimerSessionState? loadedSession = await _sessionRepository
        .loadSession();
    final TimerSessionState? sessionToUse = loadedSession ?? _initialSession;

    state = _restoreSnapshot(
      snapshot: sessionToUse,
      settings: _settings,
      now: _now(),
    );

    if (state.isRunning) {
      _startTicker();
      await _scheduleNotificationForCurrentPhase();
    } else {
      _ticker?.cancel();
      await _notificationService.cancelPhaseCompletion();
    }

    await _persistState();
  }

  Future<void> start() async {
    if (state.isRunning) {
      return;
    }

    if (!_didRequestNotificationPermission) {
      _didRequestNotificationPermission = true;
      await _notificationService.requestPermissionIfNeeded();
    }

    final DateTime now = _now();
    final int safeRemaining = max(1, state.remainingSeconds);

    state = state.copyWith(
      runState: TimerRunState.running,
      remainingSeconds: safeRemaining,
      phaseStartedAtUtc: now,
      phaseEndsAtUtc: now.add(Duration(seconds: safeRemaining)),
    );

    _startTicker();
    await _scheduleNotificationForCurrentPhase();
    await _persistState();
  }

  Future<void> pause() async {
    if (!state.isRunning) {
      return;
    }

    final RunningResolution resolution = _resolveRunningState(state, _now());

    state = resolution.state.copyWith(
      runState: TimerRunState.paused,
      clearPhaseStartedAtUtc: true,
      clearPhaseEndsAtUtc: true,
    );

    _ticker?.cancel();
    await _notificationService.cancelPhaseCompletion();
    await _persistState();
  }

  Future<void> reset() async {
    _ticker?.cancel();
    await _notificationService.cancelPhaseCompletion();

    state = TimerSessionState(
      phase: TimerPhase.pomodoro,
      runState: TimerRunState.idle,
      remainingSeconds: TimerPhase.pomodoro.durationSeconds(_settings),
      completedPomodorosInCycle: 0,
      phaseStartedAtUtc: null,
      phaseEndsAtUtc: null,
    );

    await _persistState();
  }

  Future<void> applySettings(PomodoroSettings settings) async {
    if (!state.isIdle) {
      throw StateError('Settings can only be changed while timer is idle.');
    }
    if (!settings.isValid) {
      throw ArgumentError(
        'Settings duration values must be between 1 and 120.',
      );
    }

    _settings = settings;
    state = state.copyWith(
      remainingSeconds: state.phase.durationSeconds(settings),
      clearPhaseStartedAtUtc: true,
      clearPhaseEndsAtUtc: true,
    );

    await _persistState();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onTick());
    });
  }

  Future<void> _onTick() async {
    if (!state.isRunning) {
      return;
    }

    final RunningResolution resolution = _resolveRunningState(state, _now());
    final bool changed = resolution.state != state;

    if (!changed) {
      return;
    }

    state = resolution.state;

    if (resolution.completedPhases > 0) {
      await _audioCueService.playPhaseCompleteCue();
      await _scheduleNotificationForCurrentPhase();
    }

    await _persistState();
  }

  TimerSessionState _restoreSnapshot({
    required TimerSessionState? snapshot,
    required PomodoroSettings settings,
    required DateTime now,
  }) {
    if (snapshot == null) {
      return TimerSessionState.idle(settings);
    }

    if (snapshot.isRunning) {
      if (snapshot.phaseStartedAtUtc == null ||
          snapshot.phaseEndsAtUtc == null) {
        return TimerSessionState.idle(settings);
      }

      return _resolveRunningState(snapshot, now).state;
    }

    final int maxDuration = snapshot.phase.durationSeconds(settings);
    return snapshot.copyWith(
      remainingSeconds: snapshot.remainingSeconds.clamp(1, maxDuration),
      completedPomodorosInCycle: snapshot.completedPomodorosInCycle.clamp(0, 4),
      clearPhaseStartedAtUtc: true,
      clearPhaseEndsAtUtc: true,
    );
  }

  RunningResolution _resolveRunningState(
    TimerSessionState runningState,
    DateTime now,
  ) {
    final DateTime end = runningState.phaseEndsAtUtc!;

    final int remainingSeconds = _remainingSeconds(end, now);
    if (remainingSeconds > 0) {
      return RunningResolution(
        state: runningState.copyWith(remainingSeconds: remainingSeconds),
      );
    }

    int completedPhases = 0;
    DateTime phaseStart = end;
    TimerPhase phase = runningState.phase;
    int cycle = runningState.completedPomodorosInCycle;

    while (true) {
      completedPhases += 1;
      final PhaseProgression progression = _nextPhaseAfterCompletion(
        completedPhase: phase,
        completedPomodorosInCycle: cycle,
      );

      phase = progression.nextPhase;
      cycle = progression.completedPomodorosInCycle;

      final DateTime phaseEnd = phaseStart.add(
        Duration(seconds: phase.durationSeconds(_settings)),
      );

      final int nextRemaining = _remainingSeconds(phaseEnd, now);
      if (nextRemaining > 0) {
        return RunningResolution(
          state: TimerSessionState(
            phase: phase,
            runState: TimerRunState.running,
            remainingSeconds: nextRemaining,
            completedPomodorosInCycle: cycle,
            phaseStartedAtUtc: phaseStart,
            phaseEndsAtUtc: phaseEnd,
          ),
          completedPhases: completedPhases,
        );
      }

      phaseStart = phaseEnd;
    }
  }

  PhaseProgression _nextPhaseAfterCompletion({
    required TimerPhase completedPhase,
    required int completedPomodorosInCycle,
  }) {
    switch (completedPhase) {
      case TimerPhase.pomodoro:
        final int incremented = min(4, completedPomodorosInCycle + 1);
        if (incremented >= 4) {
          return const PhaseProgression(
            nextPhase: TimerPhase.longBreak,
            completedPomodorosInCycle: 4,
          );
        }

        return PhaseProgression(
          nextPhase: TimerPhase.shortBreak,
          completedPomodorosInCycle: incremented,
        );
      case TimerPhase.shortBreak:
        return PhaseProgression(
          nextPhase: TimerPhase.pomodoro,
          completedPomodorosInCycle: completedPomodorosInCycle,
        );
      case TimerPhase.longBreak:
        return const PhaseProgression(
          nextPhase: TimerPhase.pomodoro,
          completedPomodorosInCycle: 0,
        );
    }
  }

  int _remainingSeconds(DateTime end, DateTime now) {
    final int deltaMs = end.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    if (deltaMs <= 0) {
      return 0;
    }
    return (deltaMs / 1000).ceil();
  }

  Future<void> _scheduleNotificationForCurrentPhase() async {
    if (!state.isRunning || state.phaseEndsAtUtc == null) {
      return;
    }

    final ({String title, String body}) message = _notificationMessage();

    await _notificationService.schedulePhaseCompletion(
      phaseEndsAtUtc: state.phaseEndsAtUtc!,
      phase: state.phase,
      title: message.title,
      body: message.body,
    );
  }

  ({String title, String body}) _notificationMessage() {
    final LocaleMode mode = _settings.localeMode;
    final String languageCode;

    switch (mode) {
      case LocaleMode.en:
        languageCode = 'en';
      case LocaleMode.es419:
        languageCode = 'es';
      case LocaleMode.system:
        languageCode = PlatformDispatcher.instance.locale.languageCode;
    }

    if (languageCode == 'es') {
      return (
        title: 'Fase completada',
        body: 'Tu temporizador pasó a la siguiente fase',
      );
    }

    return (
      title: 'Phase complete',
      body: 'Your timer has moved to the next phase',
    );
  }

  Future<void> _persistState() async {
    await _sessionRepository.saveSession(state);
  }
}

class PhaseProgression {
  const PhaseProgression({
    required this.nextPhase,
    required this.completedPomodorosInCycle,
  });

  final TimerPhase nextPhase;
  final int completedPomodorosInCycle;
}

class RunningResolution {
  const RunningResolution({required this.state, this.completedPhases = 0});

  final TimerSessionState state;
  final int completedPhases;
}
