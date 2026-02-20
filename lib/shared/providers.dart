import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/pomodoro_settings.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/timer/application/timer_controller.dart';
import '../features/timer/domain/session_repository.dart';
import '../features/timer/domain/timer_models.dart';
import '../services/audio/audio_cue_service.dart';
import '../services/notifications/notification_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden.');
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError('sessionRepositoryProvider must be overridden.');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden.');
});

final notificationFallbackEventCounterProvider = StateProvider<int>((ref) {
  return 0;
});

final audioCueServiceProvider = Provider<AudioCueService>((ref) {
  throw UnimplementedError('audioCueServiceProvider must be overridden.');
});

final nowProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

final initialSettingsProvider = Provider<PomodoroSettings>((ref) {
  return PomodoroSettings.defaults();
});

final initialSessionProvider = Provider<TimerSessionState?>((ref) {
  return null;
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, PomodoroSettings>((ref) {
      return SettingsController(
        repository: ref.watch(settingsRepositoryProvider),
        initialSettings: ref.watch(initialSettingsProvider),
      );
    });

final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerSessionState>((ref) {
      return TimerController(
        initialSettings: ref.read(settingsControllerProvider),
        initialSession: ref.watch(initialSessionProvider),
        sessionRepository: ref.watch(sessionRepositoryProvider),
        notificationService: ref.watch(notificationServiceProvider),
        audioCueService: ref.watch(audioCueServiceProvider),
        now: ref.watch(nowProvider),
        onNotificationFallback: () {
          final StateController<int> counter = ref.read(
            notificationFallbackEventCounterProvider.notifier,
          );
          counter.state = counter.state + 1;
        },
      );
    });
