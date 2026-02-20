// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Ya Pomodoro';

  @override
  String get pomodoroPhase => 'Pomodoro';

  @override
  String get shortBreakPhase => 'Descanso';

  @override
  String get longBreakPhase => 'Descanso largo';

  @override
  String get startButton => 'Iniciar';

  @override
  String get pauseButton => 'Pausar';

  @override
  String get resumeButton => 'Reanudar';

  @override
  String get resetButton => 'Reiniciar todo';

  @override
  String get resetWorkButton => 'Reiniciar trabajo';

  @override
  String get settingsButton => 'Configuración';

  @override
  String cycleProgress(int completed) {
    return 'Ciclo $completed/4';
  }

  @override
  String fullCyclesLabel(int count) {
    return 'Ciclos completos $count';
  }

  @override
  String get pomodoroDurationLabel => 'Pomodoro (minutos)';

  @override
  String get shortBreakDurationLabel => 'Descanso (minutos)';

  @override
  String get longBreakDurationLabel => 'Descanso largo (minutos)';

  @override
  String get showCycleProgressLabel => 'Mostrar progreso del ciclo';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanishLatam => 'Español (LatAm)';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get settingsLockedMessage =>
      'Detén el temporizador para editar la configuración.';

  @override
  String get invalidDuration => 'Usa un valor entre 1 y 120.';

  @override
  String get notificationInexactFallbackNotice =>
      'Las alarmas exactas no están disponibles. Las notificaciones podrían retrasarse un poco.';

  @override
  String get notificationPhaseCompleteTitle => 'Fase completada';

  @override
  String get notificationPhaseCompleteBody =>
      'Tu temporizador pasó a la siguiente fase';
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class AppLocalizationsEs419 extends AppLocalizationsEs {
  AppLocalizationsEs419() : super('es_419');

  @override
  String get appTitle => 'Ya Pomodoro';

  @override
  String get pomodoroPhase => 'Pomodoro';

  @override
  String get shortBreakPhase => 'Descanso';

  @override
  String get longBreakPhase => 'Descanso largo';

  @override
  String get startButton => 'Iniciar';

  @override
  String get pauseButton => 'Pausar';

  @override
  String get resumeButton => 'Reanudar';

  @override
  String get resetButton => 'Reiniciar todo';

  @override
  String get resetWorkButton => 'Reiniciar trabajo';

  @override
  String get settingsButton => 'Configuración';

  @override
  String cycleProgress(int completed) {
    return 'Ciclo $completed/4';
  }

  @override
  String fullCyclesLabel(int count) {
    return 'Ciclos completos $count';
  }

  @override
  String get pomodoroDurationLabel => 'Pomodoro (minutos)';

  @override
  String get shortBreakDurationLabel => 'Descanso (minutos)';

  @override
  String get longBreakDurationLabel => 'Descanso largo (minutos)';

  @override
  String get showCycleProgressLabel => 'Mostrar progreso del ciclo';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanishLatam => 'Español (LatAm)';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get settingsLockedMessage =>
      'Detén el temporizador para editar la configuración.';

  @override
  String get invalidDuration => 'Usa un valor entre 1 y 120.';

  @override
  String get notificationInexactFallbackNotice =>
      'Las alarmas exactas no están disponibles. Las notificaciones podrían retrasarse un poco.';

  @override
  String get notificationPhaseCompleteTitle => 'Fase completada';

  @override
  String get notificationPhaseCompleteBody =>
      'Tu temporizador pasó a la siguiente fase';
}
