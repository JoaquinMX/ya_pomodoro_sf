import '../../features/timer/domain/timer_models.dart';

enum NotificationScheduleOutcome { exactScheduled, inexactFallbackScheduled }

abstract class NotificationService {
  Future<void> init();
  Future<void> requestPermissionIfNeeded();
  Future<NotificationScheduleOutcome> schedulePhaseCompletion({
    required DateTime phaseEndsAtUtc,
    required TimerPhase phase,
    required String title,
    required String body,
  });
  Future<void> cancelPhaseCompletion();
}
