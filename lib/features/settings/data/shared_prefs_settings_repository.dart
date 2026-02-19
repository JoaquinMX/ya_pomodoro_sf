import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pomodoro_settings.dart';
import '../domain/settings_repository.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _pomodoroMinutesKey = 'settings.pomodoroMinutes';
  static const String _shortBreakMinutesKey = 'settings.shortBreakMinutes';
  static const String _longBreakMinutesKey = 'settings.longBreakMinutes';
  static const String _showCycleProgressKey = 'settings.showCycleProgress';
  static const String _localeModeKey = 'settings.localeMode';

  @override
  Future<PomodoroSettings> load() async {
    final Map<String, Object?> values = <String, Object?>{
      'pomodoroMinutes': _prefs.getInt(_pomodoroMinutesKey),
      'shortBreakMinutes': _prefs.getInt(_shortBreakMinutesKey),
      'longBreakMinutes': _prefs.getInt(_longBreakMinutesKey),
      'showCycleProgress': _prefs.getBool(_showCycleProgressKey),
      'localeMode': _prefs.getString(_localeModeKey),
    };

    return PomodoroSettings.fromStorageMap(values);
  }

  @override
  Future<void> save(PomodoroSettings settings) async {
    final Map<String, Object> map = settings.toStorageMap();
    await _prefs.setInt(_pomodoroMinutesKey, map['pomodoroMinutes']! as int);
    await _prefs.setInt(
      _shortBreakMinutesKey,
      map['shortBreakMinutes']! as int,
    );
    await _prefs.setInt(_longBreakMinutesKey, map['longBreakMinutes']! as int);
    await _prefs.setBool(
      _showCycleProgressKey,
      map['showCycleProgress']! as bool,
    );
    await _prefs.setString(_localeModeKey, map['localeMode']! as String);
  }
}
