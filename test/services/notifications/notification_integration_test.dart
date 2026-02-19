import 'package:flutter_test/flutter_test.dart';
import 'package:ya_pomodoro_sf/features/settings/domain/pomodoro_settings.dart';
import 'package:ya_pomodoro_sf/features/timer/application/timer_controller.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';

import '../../test_doubles.dart';

void main() {
  test(
    'notification scheduling and cancelation follow timer controls',
    () async {
      final MutableClock clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
      final InMemorySessionRepository sessionRepository =
          InMemorySessionRepository();
      final FakeNotificationService notifications = FakeNotificationService();
      final FakeAudioCueService audio = FakeAudioCueService();

      final TimerController controller = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: const TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.idle,
          remainingSeconds: 25 * 60,
          completedPomodorosInCycle: 0,
        ),
        sessionRepository: sessionRepository,
        notificationService: notifications,
        audioCueService: audio,
        now: clock.call,
      );
      addTearDown(controller.dispose);

      await controller.start();
      expect(notifications.scheduledCalls.length, 1);

      await controller.pause();
      expect(notifications.cancelCalls, 1);

      await controller.start();
      expect(notifications.scheduledCalls.length, 2);

      await controller.reset();
      expect(notifications.cancelCalls, 2);
    },
  );
}
