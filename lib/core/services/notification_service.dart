import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Set this callback to handle notification taps (e.g. navigate to Tasks tab).
  static void Function(String? payload)? onTapCallback;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz_data.initializeTimeZones();
    try {
      final dynamic locationResult = await FlutterTimezone.getLocalTimezone();
      if (locationResult != null) {
        // Handle cases where the result is like "TimezoneInfo(Asia/Kolkata, ...)"
        String cleanId = locationResult.toString();
        if (cleanId.contains('(') && cleanId.contains(')')) {
          final start = cleanId.indexOf('(') + 1;
          final commaIndex = cleanId.indexOf(',');
          final closingParenIndex = cleanId.indexOf(')');
          final end = (commaIndex != -1 && commaIndex > start) 
              ? commaIndex 
              : closingParenIndex;
          
          if (end > start) {
            cleanId = cleanId.substring(start, end).trim();
          }
        }
        tz.setLocalLocation(tz.getLocation(cleanId));
      } else {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Timezone initialization failed, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Platform Initialization Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 3. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onTapCallback?.call(response.payload);
      },
    );

    // 4. Request Permissions (Android 13+)
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Always check if the date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Skipping notification in the past: $scheduledDate');
      return;
    }

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      debugPrint('Scheduling notification: $id - $title at $tzDate');
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Notification scheduled successfully: $id');
    } catch (e) {
      debugPrint('Notification scheduling failed (exact): $e. Trying inexact...');
      // Fallback to inexact
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders_inexact',
              'Task Reminders (Inexact)',
              channelDescription: 'Notifications for task reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('Notification scheduled successfully (inexact): $id');
      } catch (e2) {
        debugPrint('Notification scheduling failed completely: $e2');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
