import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_settings.dart';
import '../domain/settings_repository.dart';

class SettingsController extends StateNotifier<PomodoroSettings> {
  SettingsController({
    required SettingsRepository repository,
    required PomodoroSettings initialSettings,
  }) : _repository = repository,
       super(initialSettings);

  final SettingsRepository _repository;

  Future<void> saveSettings(PomodoroSettings settings) async {
    if (!settings.isValid) {
      throw ArgumentError(
        'Settings duration values must be between 1 and 120.',
      );
    }

    state = settings;
    await _repository.save(settings);
  }
}
