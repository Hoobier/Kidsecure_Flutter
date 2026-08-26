import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// lib/core/constants/services/notification_service.dart

/// Must be a top-level function. Registered in main.dart BEFORE runApp():
/// `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);`
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS tray shows the notification automatically when a "notification"
  // payload is present (which every message sent by the backend has) —
  // this hook is reserved for extra background handling if needed later.
}

/// Handles FCM setup, token registration with the Laravel backend, and
/// local notification display for real-time student entry/exit alerts.
///
/// Call `NotificationService.instance.initialize()` once, right after a
/// successful login (and again on app start if the user is already
/// logged in — it's safe to call multiple times, it no-ops after the
/// first successful run for a given login session).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const _channelId = 'kidsecure_scan_events';

  Future<void> initialize() async {
    if (_initialized) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    _initialized = true;

    await _requestPermission();
    await _setupLocalNotifications();
    await _saveTokenToBackend();

    _messaging.onTokenRefresh.listen(_updateToken);
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // TODO: deep-link to the relevant student's status/logs screen
      // using message.data['studentId'].
    });

    // Handles the case where the app was fully closed and the user
    // tapped the notification to open it (cold start).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // TODO: deep-link using initialMessage.data['studentId'].
    }
  }

  /// Call this on logout so a different parent logging in on the same
  /// device gets their own token saved on next initialize().
  void reset() {
    _initialized = false;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings: settings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        'Entry & Exit Alerts',
        description: 'Notifies you when your child scans in or out at school.',
        importance: Importance.high,
      );
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Entry & Exit Alerts',
      channelDescription:
          'Notifies you when your child scans in or out at school.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  Future<void> _saveTokenToBackend() async {
    final token = await _messaging.getToken();
    if (token != null) await _updateToken(token);
  }

  Future<void> _updateToken(String token) async {
    try {
      await ApiService.instance.updateFcmToken(token);
    } on ApiException catch (e) {
      // Non-fatal — worst case the parent just won't get pushes until
      // the token successfully saves on a later app open.
      // ignore: avoid_print
      print('Failed to save FCM token: ${e.message}');
    }
  }
}
