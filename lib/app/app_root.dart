import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/pomodoro_settings.dart';
import '../features/timer/presentation/timer_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/providers.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(timerControllerProvider.notifier).restoreOnLaunch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PomodoroSettings settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      title: 'Ya Pomodoro',
      debugShowCheckedModeBanner: false,
      locale: _resolvedLocaleFromMode(settings.localeMode),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale.fromSubtags(languageCode: 'es', countryCode: '419'),
      ],
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
            if (locale == null) {
              return const Locale('en');
            }

            if (locale.languageCode == 'es') {
              return const Locale.fromSubtags(
                languageCode: 'es',
                countryCode: '419',
              );
            }

            return const Locale('en');
          },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2754FF),
          brightness: Brightness.light,
        ),
      ),
      home: const TimerScreen(),
    );
  }

  Locale? _resolvedLocaleFromMode(LocaleMode mode) {
    switch (mode) {
      case LocaleMode.system:
        return null;
      case LocaleMode.en:
        return const Locale('en');
      case LocaleMode.es419:
        return const Locale.fromSubtags(languageCode: 'es', countryCode: '419');
    }
  }
}
