import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/timer/domain/timer_models.dart';
import 'notification_service.dart';

class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _phaseCompleteNotificationId = 4200;

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
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> schedulePhaseCompletion({
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

    await _plugin.zonedSchedule(
      _phaseCompleteNotificationId,
      title,
      body,
      scheduleAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  @override
  Future<void> cancelPhaseCompletion() async {
    await _plugin.cancel(_phaseCompleteNotificationId);
  }
}
