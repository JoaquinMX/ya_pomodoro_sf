import '../../features/timer/domain/timer_models.dart';

abstract class NotificationService {
  Future<void> init();
  Future<void> requestPermissionIfNeeded();
  Future<void> schedulePhaseCompletion({
    required DateTime phaseEndsAtUtc,
    required TimerPhase phase,
    required String title,
    required String body,
  });
  Future<void> cancelPhaseCompletion();
}
