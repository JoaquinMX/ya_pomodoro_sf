# Ya Pomodoro SF

Minimal Pomodoro timer app for iOS and Android, built with Flutter. The project prioritizes timer accuracy, offline-first behavior, and clean state management over feature sprawl.

## Overview

Ya Pomodoro SF is a single-screen productivity timer that supports Pomodoro, short break, and long break phases. The app is designed to be reliable in foreground/background usage, restore in-progress sessions after app restarts, and keep configuration local with no backend dependency.

## Technical Highlights

- Riverpod-based state management with feature-oriented module boundaries.
- Wall-clock-driven timer progression (not decrement-only), improving accuracy across backgrounding and restores.
- Session and settings persistence via `SharedPreferences`.
- Local notification scheduling with Android exact-alarm fallback to inexact mode when exact alarms are not permitted.
- Localization support for English and Spanish (LatAm).
- Automated coverage across controller logic, widget behavior, and notification service integration paths.

## Features

- Start, pause/resume, and reset controls.
- `Reset work` action for Pomodoro intervals without clearing full cycle progress.
- Configurable Pomodoro, short-break, and long-break durations.
- Automatic phase progression with long break cadence.
- Cycle progress and full-cycle totals shown on the main screen.
- Localized UI strings and language override in settings.
- Local notifications and completion sound cues.

## Tech Stack

- Flutter + Dart
- State management: `flutter_riverpod`
- Local storage: `shared_preferences`
- Notifications: `flutter_local_notifications`, `timezone`
- Audio cues: `audioplayers`
- Testing: `flutter_test`, `mocktail`, `fake_async`

## Project Structure

```text
lib/
  app/                    # App bootstrap and root widget
  features/
    settings/             # Settings domain/application/data/presentation
    timer/                # Timer domain/application/data/presentation
  services/
    audio/                # Audio cue abstraction + implementation
    notifications/        # Notification abstraction + implementation
  l10n/                   # ARB files + generated localizations
  shared/                 # Shared providers/wiring
test/
  features/timer/         # Controller + widget tests
  services/               # Notification + audio tests
```

## Prerequisites

- Flutter SDK (project uses Dart `^3.10.1`; use a compatible stable Flutter release).
- Xcode installed for iOS builds.
- Android Studio + Android SDK for Android builds.
- At least one simulator/emulator or physical device.

## Setup

```bash
flutter pub get
flutter gen-l10n
```

No backend, API keys, or environment variables are required.

## Run (Debug)

```bash
# Auto-select connected target
flutter run

# iOS target
flutter run -d ios

# Android target
flutter run -d android
```

On first timer start, the app may request notification-related permissions depending on platform/OS behavior.

## Build (Release)

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

Notes:

- iOS signing and distribution are managed outside `flutter build ios` (Xcode/Apple Developer configuration required).
- Android production releases require proper signing config setup before distribution.

## Quality Checks

```bash
flutter analyze
flutter test
```

Recommended: run both checks before creating a PR.

## Current Scope and Limitations

- Mobile scope only (iOS and Android).
- Single-screen UX; no separate history/stats dashboard.
- No cloud sync, accounts, or telemetry backend.

## AI-Augmented Development

This project uses AI assistance for parts of implementation and documentation, with human review retained as the final authority.

- Human ownership: architecture, behavior decisions, and acceptance criteria are reviewed and approved by a human engineer.
- Required validation gates for AI-assisted changes:
  - `flutter analyze`
  - `flutter test`
  - targeted manual QA for user-critical flows
- Risk controls:
  - no blind acceptance of generated code
  - no secret material provided in prompts
  - significant behavior verified through tests or manual scenarios
- Outcome: AI is used to accelerate iteration speed, while engineering rigor and release quality remain human-controlled.
