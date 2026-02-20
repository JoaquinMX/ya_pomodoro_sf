import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/timer/domain/timer_models.dart';
import 'notification_service.dart';

class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _phaseCompleteNotificationId = 4200;
  static const String _exactAlarmsErrorCode = 'exact_alarms_not_permitted';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _didInitialize = false;

  @override
  Future<void> init() async {
    if (_didInitialize) {
      return;
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _didInitialize = true;
  }

  @override
  Future<void> requestPermissionIfNeeded() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _androidImplementation();
    await androidImpl?.requestNotificationsPermission();
    await _requestExactAlarmPermissionIfNeeded(androidImpl);

    final IOSFlutterLocalNotificationsPlugin? iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<NotificationScheduleOutcome> schedulePhaseCompletion({
    required DateTime phaseEndsAtUtc,
    required TimerPhase phase,
    required String title,
    required String body,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final DateTime safeDate = phaseEndsAtUtc.isAfter(now)
        ? phaseEndsAtUtc
        : now.add(const Duration(seconds: 1));

    final tz.TZDateTime scheduleAt = tz.TZDateTime.from(safeDate, tz.local);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_phase_channel',
          'Pomodoro Phase Alerts',
          channelDescription: 'Notifies when a timer phase completes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          ticker: phase.storageValue,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final AndroidScheduleMode scheduleMode = await _preferredScheduleMode();

    try {
      await _schedule(
        title: title,
        body: body,
        scheduleAt: scheduleAt,
        details: details,
        scheduleMode: scheduleMode,
      );
      return scheduleMode == AndroidScheduleMode.exactAllowWhileIdle
          ? NotificationScheduleOutcome.exactScheduled
          : NotificationScheduleOutcome.inexactFallbackScheduled;
    } on PlatformException catch (error) {
      if (error.code != _exactAlarmsErrorCode ||
          scheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        rethrow;
      }

      await _schedule(
        title: title,
        body: body,
        scheduleAt: scheduleAt,
        details: details,
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return NotificationScheduleOutcome.inexactFallbackScheduled;
    }
  }

  @override
  Future<void> cancelPhaseCompletion() async {
    await _plugin.cancel(_phaseCompleteNotificationId);
  }

  AndroidFlutterLocalNotificationsPlugin? _androidImplementation() {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  Future<void> _requestExactAlarmPermissionIfNeeded(
    AndroidFlutterLocalNotificationsPlugin? androidImpl,
  ) async {
    if (androidImpl == null) {
      return;
    }

    final bool canScheduleExactNow =
        await androidImpl.canScheduleExactNotifications() ?? true;
    if (canScheduleExactNow) {
      return;
    }

    await androidImpl.requestExactAlarmsPermission();
  }

  Future<AndroidScheduleMode> _preferredScheduleMode() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _androidImplementation();
    if (androidImpl == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final bool canScheduleExact =
        await androidImpl.canScheduleExactNotifications() ?? true;
    if (canScheduleExact) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _schedule({
    required String title,
    required String body,
    required tz.TZDateTime scheduleAt,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
  }) async {
    await _plugin.zonedSchedule(
      _phaseCompleteNotificationId,
      title,
      body,
      scheduleAt,
      details,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }
}
