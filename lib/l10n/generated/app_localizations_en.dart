// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ya Pomodoro';

  @override
  String get pomodoroPhase => 'Pomodoro';

  @override
  String get shortBreakPhase => 'Break';

  @override
  String get longBreakPhase => 'Long Break';

  @override
  String get startButton => 'Start';

  @override
  String get pauseButton => 'Pause';

  @override
  String get resumeButton => 'Resume';

  @override
  String get resetButton => 'Reset';

  @override
  String get settingsButton => 'Settings';

  @override
  String cycleProgress(int completed) {
    return 'Cycle $completed/4';
  }

  @override
  String get pomodoroDurationLabel => 'Pomodoro (minutes)';

  @override
  String get shortBreakDurationLabel => 'Break (minutes)';

  @override
  String get longBreakDurationLabel => 'Long break (minutes)';

  @override
  String get showCycleProgressLabel => 'Show cycle progress';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanishLatam => 'Español (LatAm)';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get settingsLockedMessage => 'Stop the timer to edit settings.';

  @override
  String get invalidDuration => 'Use a value between 1 and 120.';

  @override
  String get notificationPhaseCompleteTitle => 'Phase complete';

  @override
  String get notificationPhaseCompleteBody =>
      'Your timer has moved to the next phase';
}
