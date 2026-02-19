import 'package:flutter_test/flutter_test.dart';
import 'package:ya_pomodoro_sf/features/settings/domain/pomodoro_settings.dart';
import 'package:ya_pomodoro_sf/features/timer/application/timer_controller.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';

import '../../../test_doubles.dart';

void main() {
  group('TimerController', () {
    late MutableClock clock;
    late InMemorySessionRepository sessionRepository;
    late FakeNotificationService notificationService;
    late FakeAudioCueService audioService;

    setUp(() {
      clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
      sessionRepository = InMemorySessionRepository();
      notificationService = FakeNotificationService();
      audioService = FakeAudioCueService();
    });

    test('start, pause, resume, and reset follow expected behavior', () async {
      final TimerController controller = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: null,
        sessionRepository: sessionRepository,
        notificationService: notificationService,
        audioCueService: audioService,
        now: clock.call,
      );
      addTearDown(controller.dispose);

      expect(controller.state.runState, TimerRunState.idle);
      expect(controller.state.remainingSeconds, 25 * 60);

      await controller.start();
      expect(controller.state.runState, TimerRunState.running);
      expect(notificationService.permissionRequests, 1);
      expect(notificationService.scheduledCalls.length, 1);

      clock.advance(const Duration(seconds: 10));
      await controller.pause();

      expect(controller.state.runState, TimerRunState.paused);
      expect(controller.state.remainingSeconds, 25 * 60 - 10);
      expect(notificationService.cancelCalls, 1);

      await controller.start();
      expect(controller.state.runState, TimerRunState.running);
      expect(notificationService.permissionRequests, 1);
      expect(notificationService.scheduledCalls.length, 2);

      await controller.reset();
      expect(controller.state.runState, TimerRunState.idle);
      expect(controller.state.phase, TimerPhase.pomodoro);
      expect(controller.state.completedPomodorosInCycle, 0);
      expect(controller.state.remainingSeconds, 25 * 60);
      expect(notificationService.cancelCalls, 2);
    });

    test(
      'resetCurrentWorkInterval keeps running state, cycle counter, and reschedules notification',
      () async {
        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: const TimerSessionState(
            phase: TimerPhase.pomodoro,
            runState: TimerRunState.paused,
            remainingSeconds: 42,
            completedPomodorosInCycle: 2,
          ),
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        await controller.start();
        final int scheduledBefore = notificationService.scheduledCalls.length;

        await controller.resetCurrentWorkInterval();

        expect(controller.state.phase, TimerPhase.pomodoro);
        expect(controller.state.runState, TimerRunState.running);
        expect(controller.state.remainingSeconds, 25 * 60);
        expect(controller.state.completedPomodorosInCycle, 2);
        expect(controller.state.phaseStartedAtUtc, isNotNull);
        expect(controller.state.phaseEndsAtUtc, isNotNull);
        expect(notificationService.scheduledCalls.length, scheduledBefore + 1);
      },
    );

    test(
      'resetCurrentWorkInterval keeps paused state and resets only work elapsed time',
      () async {
        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: const TimerSessionState(
            phase: TimerPhase.pomodoro,
            runState: TimerRunState.paused,
            remainingSeconds: 10,
            completedPomodorosInCycle: 3,
          ),
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        await controller.resetCurrentWorkInterval();

        expect(controller.state.phase, TimerPhase.pomodoro);
        expect(controller.state.runState, TimerRunState.paused);
        expect(controller.state.remainingSeconds, 25 * 60);
        expect(controller.state.completedPomodorosInCycle, 3);
        expect(controller.state.phaseStartedAtUtc, isNull);
        expect(controller.state.phaseEndsAtUtc, isNull);
      },
    );

    test(
      'resetCurrentWorkInterval keeps idle state and resets only work elapsed time',
      () async {
        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: const TimerSessionState(
            phase: TimerPhase.pomodoro,
            runState: TimerRunState.idle,
            remainingSeconds: 10,
            completedPomodorosInCycle: 1,
          ),
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        await controller.resetCurrentWorkInterval();

        expect(controller.state.phase, TimerPhase.pomodoro);
        expect(controller.state.runState, TimerRunState.idle);
        expect(controller.state.remainingSeconds, 25 * 60);
        expect(controller.state.completedPomodorosInCycle, 1);
        expect(controller.state.phaseStartedAtUtc, isNull);
        expect(controller.state.phaseEndsAtUtc, isNull);
      },
    );

    test('resetCurrentWorkInterval does nothing on break phases', () async {
      final TimerController controller = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: const TimerSessionState(
          phase: TimerPhase.shortBreak,
          runState: TimerRunState.paused,
          remainingSeconds: 200,
          completedPomodorosInCycle: 2,
        ),
        sessionRepository: sessionRepository,
        notificationService: notificationService,
        audioCueService: audioService,
        now: clock.call,
      );
      addTearDown(controller.dispose);

      final TimerSessionState before = controller.state;
      final int scheduledBefore = notificationService.scheduledCalls.length;
      await controller.resetCurrentWorkInterval();

      expect(controller.state.phase, before.phase);
      expect(controller.state.runState, before.runState);
      expect(controller.state.remainingSeconds, before.remainingSeconds);
      expect(
        controller.state.completedPomodorosInCycle,
        before.completedPomodorosInCycle,
      );
      expect(notificationService.scheduledCalls.length, scheduledBefore);
    });

    test('fourth pomodoro completion transitions to long break', () {
      final DateTime start = DateTime.utc(2026, 1, 1, 10, 0, 0);
      clock.now = start.add(const Duration(seconds: 2));

      final TimerSessionState runningPomodoro = TimerSessionState(
        phase: TimerPhase.pomodoro,
        runState: TimerRunState.running,
        remainingSeconds: 1,
        completedPomodorosInCycle: 3,
        phaseStartedAtUtc: start,
        phaseEndsAtUtc: start.add(const Duration(seconds: 1)),
      );

      final TimerController controller = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: runningPomodoro,
        sessionRepository: sessionRepository,
        notificationService: notificationService,
        audioCueService: audioService,
        now: clock.call,
      );
      addTearDown(controller.dispose);

      expect(controller.state.phase, TimerPhase.longBreak);
      expect(controller.state.runState, TimerRunState.running);
      expect(controller.state.completedPomodorosInCycle, 4);
    });

    test(
      'long break completion resets cycle to zero and returns to pomodoro',
      () {
        final DateTime start = DateTime.utc(2026, 1, 1, 8, 0, 0);
        clock.now = start.add(const Duration(seconds: 2));

        final TimerSessionState runningLongBreak = TimerSessionState(
          phase: TimerPhase.longBreak,
          runState: TimerRunState.running,
          remainingSeconds: 1,
          completedPomodorosInCycle: 4,
          phaseStartedAtUtc: start,
          phaseEndsAtUtc: start.add(const Duration(seconds: 1)),
        );

        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: runningLongBreak,
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        expect(controller.state.phase, TimerPhase.pomodoro);
        expect(controller.state.runState, TimerRunState.running);
        expect(controller.state.completedPomodorosInCycle, 0);
      },
    );

    test(
      'restore catch-up can advance multiple phases using wall-clock time',
      () {
        final PomodoroSettings oneMinuteSettings = const PomodoroSettings(
          pomodoroMinutes: 1,
          shortBreakMinutes: 1,
          longBreakMinutes: 1,
          showCycleProgress: true,
          localeMode: LocaleMode.en,
        );

        final DateTime start = DateTime.utc(2026, 1, 1, 6, 0, 0);
        clock.now = start.add(const Duration(seconds: 190));

        final TimerSessionState runningPomodoro = TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.running,
          remainingSeconds: 60,
          completedPomodorosInCycle: 0,
          phaseStartedAtUtc: start,
          phaseEndsAtUtc: start.add(const Duration(seconds: 60)),
        );

        final TimerController controller = TimerController(
          initialSettings: oneMinuteSettings,
          initialSession: runningPomodoro,
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        expect(controller.state.phase, TimerPhase.shortBreak);
        expect(controller.state.completedPomodorosInCycle, 2);
        expect(controller.state.remainingSeconds, 50);
      },
    );

    test(
      'applySettings validates bounds and blocks non-idle updates',
      () async {
        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: null,
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        const PomodoroSettings validSettings = PomodoroSettings(
          pomodoroMinutes: 30,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          showCycleProgress: true,
          localeMode: LocaleMode.en,
        );

        await controller.applySettings(validSettings);
        expect(controller.state.remainingSeconds, 30 * 60);

        await controller.start();

        const PomodoroSettings anotherSettings = PomodoroSettings(
          pomodoroMinutes: 20,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          showCycleProgress: true,
          localeMode: LocaleMode.en,
        );

        await expectLater(
          () => controller.applySettings(anotherSettings),
          throwsA(isA<StateError>()),
        );

        await controller.pause();
        await expectLater(
          () => controller.applySettings(anotherSettings),
          throwsA(isA<StateError>()),
        );

        await controller.reset();

        const PomodoroSettings invalidSettings = PomodoroSettings(
          pomodoroMinutes: 0,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          showCycleProgress: true,
          localeMode: LocaleMode.en,
        );
        await expectLater(
          () => controller.applySettings(invalidSettings),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('restoreOnLaunch uses repository snapshot when available', () async {
      final DateTime start = DateTime.utc(2026, 1, 1, 14, 0, 0);
      clock.now = start;

      final TimerController controller = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: null,
        sessionRepository: sessionRepository,
        notificationService: notificationService,
        audioCueService: audioService,
        now: clock.call,
      );
      addTearDown(controller.dispose);

      sessionRepository = InMemorySessionRepository(
        TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.running,
          remainingSeconds: 10,
          completedPomodorosInCycle: 0,
          phaseStartedAtUtc: start,
          phaseEndsAtUtc: start.add(const Duration(seconds: 10)),
        ),
      );

      final TimerController loadedController = TimerController(
        initialSettings: PomodoroSettings.defaults(),
        initialSession: null,
        sessionRepository: sessionRepository,
        notificationService: notificationService,
        audioCueService: audioService,
        now: clock.call,
      );
      addTearDown(loadedController.dispose);

      clock.advance(const Duration(seconds: 2));
      await loadedController.restoreOnLaunch();
      expect(loadedController.state.runState, TimerRunState.running);
      expect(loadedController.state.remainingSeconds, 8);
    });

    test(
      'plays completion sound when phase transitions in foreground ticker',
      () async {
        final DateTime start = DateTime.utc(2026, 1, 1, 9, 0, 0);
        clock.now = start;

        final TimerSessionState runningPomodoro = TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.running,
          remainingSeconds: 1,
          completedPomodorosInCycle: 0,
          phaseStartedAtUtc: start,
          phaseEndsAtUtc: start.add(const Duration(seconds: 1)),
        );

        final TimerController controller = TimerController(
          initialSettings: PomodoroSettings.defaults(),
          initialSession: runningPomodoro,
          sessionRepository: sessionRepository,
          notificationService: notificationService,
          audioCueService: audioService,
          now: clock.call,
        );
        addTearDown(controller.dispose);

        clock.advance(const Duration(seconds: 2));
        await Future<void>.delayed(const Duration(milliseconds: 1200));

        expect(audioService.playCount, greaterThanOrEqualTo(1));
      },
    );
  });
}
