import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Initialize FCM
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _getToken();
    _setupMessageHandlers();
  }

  // Initialize local notifications (for foreground display)
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // await _localNotifications.initialize(settings);
    await _localNotifications.initialize(settings: settings);
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM permission granted');
    } else {
      debugPrint('❌ FCM permission denied');
    }
  }

  // Get FCM token
  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📬 Foreground message received: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // Background messages (app opened from background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '📬 App opened from notification: ${message.notification?.title}',
      );
    });

    // App terminated and opened from notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint(
          '📬 App launched from terminated state: ${message.notification?.title}',
        );
      }
    });
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fcm_channel',
          'FCM Notifications',
          channelDescription: 'Notifications from Firebase',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  // Subscribe to user-specific topic
  Future<void> subscribeToUserTopic(String userId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      debugPrint('✅ Subscribed to user_$userId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe: $e');
    }
  }
}
