import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/domain/pomodoro_settings.dart';
import '../../settings/presentation/settings_sheet.dart';
import '../domain/timer_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TimerSessionState timerState = ref.watch(timerControllerProvider);
    final PomodoroSettings settings = ref.watch(settingsControllerProvider);
    final timerController = ref.read(timerControllerProvider.notifier);

    final bool isRunning = timerState.runState == TimerRunState.running;
    final bool isPaused = timerState.runState == TimerRunState.paused;
    final bool canResetWork = timerState.phase == TimerPhase.pomodoro;
    final double primaryButtonWidth = _primaryButtonWidth(context, l10n);

    final String primaryLabel = isRunning
        ? l10n.pauseButton
        : isPaused
        ? l10n.resumeButton
        : l10n.startButton;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.settingsButton,
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return SettingsSheet(isLocked: !timerState.isIdle);
                },
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _phaseColor(
                      context,
                      timerState.phase,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      _phaseLabel(l10n, timerState.phase),
                      key: ValueKey<TimerPhase>(timerState.phase),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutExpo,
                  switchOutCurve: Curves.easeInExpo,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: Text(
                    _formatDuration(timerState.remainingSeconds),
                    key: ValueKey<int>(timerState.remainingSeconds),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (settings.showCycleProgress)
                  Text(
                    l10n.cycleProgress(timerState.completedPomodorosInCycle),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: 28),
                Column(
                  children: <Widget>[
                    Row(
                      key: const Key('action-row-primary'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          key: const Key('primary-action-wrapper'),
                          width: primaryButtonWidth,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: FilledButton(
                              key: ValueKey<String>('primary-$primaryLabel'),
                              onPressed: () async {
                                if (isRunning) {
                                  await timerController.pause();
                                  return;
                                }
                                await timerController.start();
                              },
                              child: Text(primaryLabel),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: canResetWork
                              ? () => timerController.resetCurrentWorkInterval()
                              : null,
                          child: Text(l10n.resetWorkButton),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      key: const Key('action-row-reset-all'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          key: const Key('reset-all-button'),
                          onPressed: () => timerController.reset(),
                          child: Text(l10n.resetButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _phaseColor(BuildContext context, TimerPhase phase) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (phase) {
      case TimerPhase.pomodoro:
        return scheme.primary;
      case TimerPhase.shortBreak:
        return scheme.tertiary;
      case TimerPhase.longBreak:
        return scheme.secondary;
    }
  }

  String _phaseLabel(AppLocalizations l10n, TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return l10n.pomodoroPhase;
      case TimerPhase.shortBreak:
        return l10n.shortBreakPhase;
      case TimerPhase.longBreak:
        return l10n.longBreakPhase;
    }
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _primaryButtonWidth(BuildContext context, AppLocalizations l10n) {
    final TextStyle textStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextDirection textDirection = Directionality.of(context);

    final List<String> labels = <String>[
      l10n.startButton,
      l10n.pauseButton,
      l10n.resumeButton,
    ];

    double widestLabel = 0;
    for (final String label in labels) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widestLabel = math.max(widestLabel, painter.width);
    }

    const double horizontalPadding = 48;
    const double minimumWidth = 96;
    return math.max(minimumWidth, widestLabel + horizontalPadding);
  }
}
