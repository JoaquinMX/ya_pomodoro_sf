import 'package:ya_pomodoro_sf/features/settings/domain/pomodoro_settings.dart';
import 'package:ya_pomodoro_sf/features/settings/domain/settings_repository.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/session_repository.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';
import 'package:ya_pomodoro_sf/services/audio/audio_cue_service.dart';
import 'package:ya_pomodoro_sf/services/notifications/notification_service.dart';

class MutableClock {
  MutableClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration delta) {
    now = now.add(delta);
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository(this._settings);

  PomodoroSettings _settings;
  PomodoroSettings get current => _settings;

  @override
  Future<PomodoroSettings> load() async => _settings;

  @override
  Future<void> save(PomodoroSettings settings) async {
    _settings = settings;
  }
}

class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository([this._session]);

  TimerSessionState? _session;
  TimerSessionState? get current => _session;

  @override
  Future<TimerSessionState?> loadSession() async => _session;

  @override
  Future<void> saveSession(TimerSessionState state) async {
    _session = state;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}

class NotificationCall {
  NotificationCall({
    required this.phaseEndsAtUtc,
    required this.phase,
    required this.title,
    required this.body,
  });

  final DateTime phaseEndsAtUtc;
  final TimerPhase phase;
  final String title;
  final String body;
}

class FakeNotificationService implements NotificationService {
  bool initialized = false;
  int permissionRequests = 0;
  int cancelCalls = 0;
  final List<NotificationCall> scheduledCalls = <NotificationCall>[];
  NotificationScheduleOutcome scheduleOutcome =
      NotificationScheduleOutcome.exactScheduled;
  Object? scheduleException;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<void> requestPermissionIfNeeded() async {
    permissionRequests += 1;
  }

  @override
  Future<NotificationScheduleOutcome> schedulePhaseCompletion({
    required DateTime phaseEndsAtUtc,
    required TimerPhase phase,
    required String title,
    required String body,
  }) async {
    scheduledCalls.add(
      NotificationCall(
        phaseEndsAtUtc: phaseEndsAtUtc,
        phase: phase,
        title: title,
        body: body,
      ),
    );
    if (scheduleException != null) {
      throw scheduleException!;
    }
    return scheduleOutcome;
  }

  @override
  Future<void> cancelPhaseCompletion() async {
    cancelCalls += 1;
  }
}

class FakeAudioCueService implements AudioCueService {
  int playCount = 0;

  @override
  Future<void> playPhaseCompleteCue() async {
    playCount += 1;
  }
}
