import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session_repository.dart';
import '../domain/timer_models.dart';

class SharedPrefsSessionRepository implements SessionRepository {
  SharedPrefsSessionRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _phaseKey = 'session.phase';
  static const String _runStateKey = 'session.runState';
  static const String _remainingSecondsKey = 'session.remainingSeconds';
  static const String _cycleCountKey = 'session.completedPomodorosInCycle';
  static const String _startedAtKey = 'session.phaseStartedAtUtc';
  static const String _endsAtKey = 'session.phaseEndsAtUtc';

  @override
  Future<TimerSessionState?> loadSession() async {
    final String? phaseValue = _prefs.getString(_phaseKey);
    final String? runStateValue = _prefs.getString(_runStateKey);
    final int? remainingSeconds = _prefs.getInt(_remainingSecondsKey);
    final int? cycle = _prefs.getInt(_cycleCountKey);

    if (phaseValue == null ||
        runStateValue == null ||
        remainingSeconds == null) {
      return null;
    }

    final Map<String, Object?> values = <String, Object?>{
      'phase': phaseValue,
      'runState': runStateValue,
      'remainingSeconds': remainingSeconds,
      'completedPomodorosInCycle': cycle,
      'phaseStartedAtUtc': _prefs.getString(_startedAtKey),
      'phaseEndsAtUtc': _prefs.getString(_endsAtKey),
    };

    return TimerSessionState.fromStorageMap(values);
  }

  @override
  Future<void> saveSession(TimerSessionState state) async {
    final Map<String, Object> map = state.toStorageMap();

    await _prefs.setString(_phaseKey, map['phase']! as String);
    await _prefs.setString(_runStateKey, map['runState']! as String);
    await _prefs.setInt(_remainingSecondsKey, map['remainingSeconds']! as int);
    await _prefs.setInt(
      _cycleCountKey,
      map['completedPomodorosInCycle']! as int,
    );

    final String startedAt = map['phaseStartedAtUtc']! as String;
    final String endsAt = map['phaseEndsAtUtc']! as String;

    if (startedAt.isEmpty) {
      await _prefs.remove(_startedAtKey);
    } else {
      await _prefs.setString(_startedAtKey, startedAt);
    }

    if (endsAt.isEmpty) {
      await _prefs.remove(_endsAtKey);
    } else {
      await _prefs.setString(_endsAtKey, endsAt);
    }
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_phaseKey);
    await _prefs.remove(_runStateKey);
    await _prefs.remove(_remainingSecondsKey);
    await _prefs.remove(_cycleCountKey);
    await _prefs.remove(_startedAtKey);
    await _prefs.remove(_endsAtKey);
  }
}
