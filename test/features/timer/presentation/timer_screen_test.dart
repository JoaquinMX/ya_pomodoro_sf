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
          initialSessionProvider.overrideWithValue(sessionRepository.current),
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
      expect(find.text('Reset'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(find.text('25:00'), findsOneWidget);
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
