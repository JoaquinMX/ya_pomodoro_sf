import 'timer_models.dart';

abstract class SessionRepository {
  Future<TimerSessionState?> loadSession();
  Future<void> saveSession(TimerSessionState state);
  Future<void> clearSession();
}
