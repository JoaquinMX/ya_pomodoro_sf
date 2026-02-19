import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ya_pomodoro_sf/features/settings/domain/pomodoro_settings.dart';
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';
import 'package:ya_pomodoro_sf/features/timer/presentation/timer_screen.dart';
import 'package:ya_pomodoro_sf/l10n/generated/app_localizations.dart';
import 'package:ya_pomodoro_sf/shared/providers.dart';

import '../../../test_doubles.dart';

void main() {
  group('TimerScreen', () {
    late InMemorySettingsRepository settingsRepository;
    late InMemorySessionRepository sessionRepository;
    late FakeNotificationService notificationService;
    late FakeAudioCueService audioService;
    late MutableClock clock;

    setUp(() {
      settingsRepository = InMemorySettingsRepository(
        const PomodoroSettings(
          pomodoroMinutes: 25,
          shortBreakMinutes: 5,
          longBreakMinutes: 15,
          showCycleProgress: true,
          localeMode: LocaleMode.en,
        ),
      );
      sessionRepository = InMemorySessionRepository(
        const TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.idle,
          remainingSeconds: 25 * 60,
          completedPomodorosInCycle: 0,
        ),
      );
      notificationService = FakeNotificationService();
      audioService = FakeAudioCueService();
      clock = MutableClock(DateTime.utc(2026, 1, 1, 12));
    });

    Future<ProviderContainer> pumpScreen(
      WidgetTester tester, {
      PomodoroSettings? initialSettings,
      TimerSessionState? initialSession,
    }) async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          notificationServiceProvider.overrideWithValue(notificationService),
          audioCueServiceProvider.overrideWithValue(audioService),
          nowProvider.overrideWithValue(clock.call),
          initialSettingsProvider.overrideWithValue(
            initialSettings ?? settingsRepository.current,
          ),
          initialSessionProvider.overrideWithValue(
            initialSession ?? sessionRepository.current,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final LocaleMode localeMode = ref
                  .watch(settingsControllerProvider)
                  .localeMode;
              Locale? locale;
              switch (localeMode) {
                case LocaleMode.system:
                  locale = null;
                case LocaleMode.en:
                  locale = const Locale('en');
                case LocaleMode.es419:
                  locale = const Locale.fromSubtags(
                    languageCode: 'es',
                    countryCode: '419',
                  );
              }

              return MaterialApp(
                locale: locale,
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const TimerScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('renders timer and controls, start pause resume reset flow', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Reset all'), findsOneWidget);
      expect(find.text('Reset work'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Reset all'));
      await tester.pump();
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('actions are rendered in two rows', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final Finder firstRow = find.byKey(const Key('action-row-primary'));
      final Finder secondRow = find.byKey(const Key('action-row-reset-all'));

      expect(firstRow, findsOneWidget);
      expect(secondRow, findsOneWidget);

      expect(
        find.descendant(of: firstRow, matching: find.text('Start')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: firstRow, matching: find.text('Reset work')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: firstRow, matching: find.text('Reset all')),
        findsNothing,
      );

      expect(
        find.descendant(of: secondRow, matching: find.text('Reset all')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondRow, matching: find.text('Reset work')),
        findsNothing,
      );
    });

    testWidgets('primary action button width stays stable across states', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final Finder primaryWrapper = find.byKey(
        const Key('primary-action-wrapper'),
      );
      expect(primaryWrapper, findsOneWidget);

      final double startWidth = tester.getSize(primaryWrapper).width;

      await tester.tap(find.text('Start'));
      await tester.pump();
      final double pauseWidth = tester.getSize(primaryWrapper).width;

      await tester.tap(find.text('Pause'));
      await tester.pump();
      final double resumeWidth = tester.getSize(primaryWrapper).width;

      expect(pauseWidth, closeTo(startWidth, 0.001));
      expect(resumeWidth, closeTo(startWidth, 0.001));
    });

    testWidgets('reset work is enabled only in Pomodoro phase', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      final OutlinedButton enabledResetWork = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Reset work'),
      );
      expect(enabledResetWork.onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await pumpScreen(
        tester,
        initialSession: const TimerSessionState(
          phase: TimerPhase.shortBreak,
          runState: TimerRunState.paused,
          remainingSeconds: 120,
          completedPomodorosInCycle: 2,
        ),
      );

      final OutlinedButton disabledResetWork = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Reset work'),
      );
      expect(disabledResetWork.onPressed, isNull);
    });

    testWidgets(
      'reset work restores full Pomodoro time without changing cycle progress',
      (WidgetTester tester) async {
        await pumpScreen(
          tester,
          initialSession: const TimerSessionState(
            phase: TimerPhase.pomodoro,
            runState: TimerRunState.paused,
            remainingSeconds: 10,
            completedPomodorosInCycle: 2,
          ),
        );

        expect(find.text('00:10'), findsOneWidget);
        expect(find.text('Cycle 2/4'), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);

        await tester.tap(find.text('Reset work'));
        await tester.pump();

        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('Cycle 2/4'), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);
      },
    );

    testWidgets('full reset still clears cycle and returns idle', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        initialSession: const TimerSessionState(
          phase: TimerPhase.pomodoro,
          runState: TimerRunState.paused,
          remainingSeconds: 50,
          completedPomodorosInCycle: 3,
        ),
      );

      expect(find.text('Cycle 3/4'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Reset all'));
      await tester.pump();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Cycle 0/4'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('settings sheet updates durations when idle', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      final Finder fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '1');
      await tester.enterText(fields.at(2), '2');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('cycle progress visibility follows settings toggle', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('Cycle 0/4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cycle'), findsNothing);
    });

    testWidgets('locale updates to Spanish (LatAm)', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpScreen(tester);
      expect(find.text('Start'), findsOneWidget);

      const PomodoroSettings spanishSettings = PomodoroSettings(
        pomodoroMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        showCycleProgress: true,
        localeMode: LocaleMode.es419,
      );
      await container
          .read(settingsControllerProvider.notifier)
          .saveSettings(spanishSettings);
      await container
          .read(timerControllerProvider.notifier)
          .applySettings(spanishSettings);
      await tester.pumpAndSettle();

      expect(find.text('Iniciar'), findsOneWidget);
    });
  });
}
