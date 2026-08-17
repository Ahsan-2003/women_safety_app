import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    // Combined initialization settings
    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    // Initialize plugin with settings and notification tap handler
    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions
    await requestPermissions();
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'safewalk_channel',
          'SafeWalk Notifications',
          channelDescription: 'Notifications for SafeWalk app',
          priority: Priority.high,
          importance: Importance.max,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // Schedule notification for future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'safewalk_channel',
          'SafeWalk Notifications',
          channelDescription: 'Notifications for SafeWalk app',
          priority: Priority.high,
          importance: Importance.max,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTZTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  // Show test notification (for debugging)
  Future<void> showTestNotification() async {
    await showNotification(
      id: Random().nextInt(1000),
      title: 'SafeWalk Test',
      body: 'This is a test notification from SafeWalk',
      payload: 'test_notification',
    );
  }

  // Schedule test notification (5 seconds from now)
  Future<void> scheduleTestNotification() async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 5));

    await scheduleNotification(
      id: Random().nextInt(1000),
      title: 'SafeWalk Scheduled Test',
      body: 'This notification was scheduled 5 seconds ago',
      scheduledTime: scheduledTime,
      payload: 'scheduled_test',
    );
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id: id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  // Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await notificationsPlugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    return true;
  }

  // Show notification channel details (Android only)
  Future<void> showNotificationChannelInfo() async {
    if (Platform.isAndroid) {
      final channels = await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.getNotificationChannels();

      debugPrint('Active notification channels:');
      channels?.forEach((channel) {
        debugPrint('Channel: ${channel.id} - ${channel.name}');
      });
    }
  }
}
