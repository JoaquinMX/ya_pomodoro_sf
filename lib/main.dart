import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_root.dart';
import 'features/settings/data/shared_prefs_settings_repository.dart';
import 'features/settings/domain/pomodoro_settings.dart';
import 'features/timer/data/shared_prefs_session_repository.dart';
import 'features/timer/domain/timer_models.dart';
import 'services/audio/audioplayers_audio_cue_service.dart';
import 'services/notifications/flutter_local_notification_service.dart';
import 'shared/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final SharedPrefsSettingsRepository settingsRepository =
      SharedPrefsSettingsRepository(prefs);
  final SharedPrefsSessionRepository sessionRepository =
      SharedPrefsSessionRepository(prefs);
  final FlutterLocalNotificationService notificationService =
      FlutterLocalNotificationService();

  await notificationService.init();

  final PomodoroSettings initialSettings = await settingsRepository.load();
  final TimerSessionState? initialSession = await sessionRepository
      .loadSession();

  runApp(
    ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
        audioCueServiceProvider.overrideWithValue(
          AudioplayersAudioCueService(),
        ),
        initialSettingsProvider.overrideWithValue(initialSettings),
        initialSessionProvider.overrideWithValue(initialSession),
      ],
      child: const AppRoot(),
    ),
  );
}
