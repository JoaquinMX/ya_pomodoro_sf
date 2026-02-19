import 'pomodoro_settings.dart';

abstract class SettingsRepository {
  Future<PomodoroSettings> load();
  Future<void> save(PomodoroSettings settings);
}
