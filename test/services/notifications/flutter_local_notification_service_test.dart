import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:ya_pomodoro_sf/features/timer/domain/timer_models.dart';
import 'package:ya_pomodoro_sf/services/notifications/flutter_local_notification_service.dart';
import 'package:ya_pomodoro_sf/services/notifications/notification_service.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockAndroidNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(
      tz.TZDateTime.from(DateTime.utc(2026, 1, 1, 0, 0, 0), tz.local),
    );
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(const InitializationSettings());
  });

  late _MockNotificationsPlugin plugin;
  late _MockAndroidNotificationsPlugin androidPlugin;
  late FlutterLocalNotificationService service;

  setUp(() {
    plugin = _MockNotificationsPlugin();
    androidPlugin = _MockAndroidNotificationsPlugin();
    service = FlutterLocalNotificationService(plugin: plugin);

    when(() => plugin.initialize(any())).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(androidPlugin);
  });

  Future<NotificationScheduleOutcome> scheduleNow() {
    return service.schedulePhaseCompletion(
      phaseEndsAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 1)),
      phase: TimerPhase.pomodoro,
      title: 'title',
      body: 'body',
    );
  }

  test(
    'returns exactScheduled when exact alarm scheduling is available',
    () async {
      await service.init();
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).thenAnswer((_) async {});

      final NotificationScheduleOutcome outcome = await scheduleNow();

      expect(outcome, NotificationScheduleOutcome.exactScheduled);
      verifyNever(() => androidPlugin.requestExactAlarmsPermission());
      verify(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).called(1);
    },
  );

  test(
    'returns inexactFallbackScheduled when exact permission remains unavailable',
    () async {
      await service.init();
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);
      when(
        () => androidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => androidPlugin.requestExactAlarmsPermission(),
      ).thenAnswer((_) async => false);
      when(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).thenAnswer((_) async {});

      await service.requestPermissionIfNeeded();
      final NotificationScheduleOutcome outcome = await scheduleNow();

      expect(outcome, NotificationScheduleOutcome.inexactFallbackScheduled);
      verify(() => androidPlugin.requestExactAlarmsPermission()).called(1);
      verify(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).called(1);
    },
  );

  test(
    'retries inexact schedule when exact path throws exact_alarms_not_permitted',
    () async {
      await service.init();
      when(
        () => androidPlugin.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).thenThrow(
        PlatformException(
          code: 'exact_alarms_not_permitted',
          message: 'Exact alarms are not permitted',
        ),
      );
      when(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).thenAnswer((_) async {});

      final NotificationScheduleOutcome outcome = await scheduleNow();

      expect(outcome, NotificationScheduleOutcome.inexactFallbackScheduled);
      verify(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).called(1);
      verify(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        ),
      ).called(1);
    },
  );
}
