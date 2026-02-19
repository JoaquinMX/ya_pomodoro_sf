import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_settings.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({required this.isLocked, super.key});

  final bool isLocked;

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late final TextEditingController _pomodoroController;
  late final TextEditingController _shortBreakController;
  late final TextEditingController _longBreakController;

  late bool _showCycleProgress;
  late LocaleMode _localeMode;

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final PomodoroSettings settings = ref.read(settingsControllerProvider);
    _pomodoroController = TextEditingController(
      text: settings.pomodoroMinutes.toString(),
    );
    _shortBreakController = TextEditingController(
      text: settings.shortBreakMinutes.toString(),
    );
    _longBreakController = TextEditingController(
      text: settings.longBreakMinutes.toString(),
    );
    _showCycleProgress = settings.showCycleProgress;
    _localeMode = settings.localeMode;
  }

  @override
  void dispose() {
    _pomodoroController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool locked = widget.isLocked;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.settingsButton,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (locked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l10n.settingsLockedMessage),
                ),
              if (locked) const SizedBox(height: 12),
              _buildNumberField(
                controller: _pomodoroController,
                label: l10n.pomodoroDurationLabel,
                enabled: !locked,
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _shortBreakController,
                label: l10n.shortBreakDurationLabel,
                enabled: !locked,
              ),
              const SizedBox(height: 12),
              _buildNumberField(
                controller: _longBreakController,
                label: l10n.longBreakDurationLabel,
                enabled: !locked,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _showCycleProgress,
                onChanged: locked
                    ? null
                    : (bool value) {
                        setState(() {
                          _showCycleProgress = value;
                        });
                      },
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.showCycleProgressLabel),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<LocaleMode>(
                initialValue: _localeMode,
                decoration: InputDecoration(
                  labelText: l10n.languageLabel,
                  border: const OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<LocaleMode>>[
                  DropdownMenuItem<LocaleMode>(
                    value: LocaleMode.system,
                    child: Text(l10n.languageSystem),
                  ),
                  DropdownMenuItem<LocaleMode>(
                    value: LocaleMode.en,
                    child: Text(l10n.languageEnglish),
                  ),
                  DropdownMenuItem<LocaleMode>(
                    value: LocaleMode.es419,
                    child: Text(l10n.languageSpanishLatam),
                  ),
                ],
                onChanged: locked
                    ? null
                    : (LocaleMode? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _localeMode = value;
                        });
                      },
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancelButton),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: locked || _isSaving ? null : _save,
                    child: Text(l10n.saveButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _save() async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final int? pomodoro = int.tryParse(_pomodoroController.text.trim());
    final int? shortBreak = int.tryParse(_shortBreakController.text.trim());
    final int? longBreak = int.tryParse(_longBreakController.text.trim());

    if (pomodoro == null || shortBreak == null || longBreak == null) {
      setState(() {
        _error = l10n.invalidDuration;
      });
      return;
    }

    final PomodoroSettings newSettings = PomodoroSettings(
      pomodoroMinutes: pomodoro,
      shortBreakMinutes: shortBreak,
      longBreakMinutes: longBreak,
      showCycleProgress: _showCycleProgress,
      localeMode: _localeMode,
    );

    if (!newSettings.isValid) {
      setState(() {
        _error = l10n.invalidDuration;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .saveSettings(newSettings);
      await ref
          .read(timerControllerProvider.notifier)
          .applySettings(newSettings);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = l10n.settingsLockedMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
