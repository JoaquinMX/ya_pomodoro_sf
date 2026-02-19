import 'package:flutter_test/flutter_test.dart';
import 'package:ya_pomodoro_sf/features/settings/domain/pomodoro_settings.dart';
import 'package:ya_pomodoro_sf/features/timer/application/timer_controller.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';

import '../../test_doubles.dart';

void main() {
  test('foreground completion triggers audio cue', () async {
    final DateTime start = DateTime.utc(2026, 1, 1, 12, 0, 0);
    final MutableClock clock = MutableClock(start);
    final InMemorySessionRepository sessionRepository =
        InMemorySessionRepository();
    final FakeNotificationService notifications = FakeNotificationService();
    final FakeAudioCueService audio = FakeAudioCueService();

    final TimerController controller = TimerController(
      initialSettings: PomodoroSettings.defaults(),
      initialSession: TimerSessionState(
        phase: TimerPhase.pomodoro,
        runState: TimerRunState.running,
        remainingSeconds: 1,
        completedPomodorosInCycle: 0,
        phaseStartedAtUtc: start,
        phaseEndsAtUtc: start.add(const Duration(seconds: 1)),
      ),
      sessionRepository: sessionRepository,
      notificationService: notifications,
      audioCueService: audio,
      now: clock.call,
    );
    addTearDown(controller.dispose);

    clock.advance(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(audio.playCount, greaterThanOrEqualTo(1));
  });
}
