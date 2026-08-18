import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Must be a top-level function. Register in main.dart BEFORE runApp():
/// `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);`
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS tray shows the notification automatically when a "notification"
  // payload is present; this hook is reserved for extra background handling.
}

/// Handles FCM setup and local notification display for real-time
/// student entry/exit alerts to parents.
///
/// Call `NotificationService.instance.initialize(parentUid: ...)` once,
/// right after a successful login.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const _channelId = 'kidsecure_scan_events';

  Future<void> initialize({required String parentUid}) async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _setupLocalNotifications();
    await _saveTokenToFirestore(parentUid);

    _messaging.onTokenRefresh.listen((token) => _updateToken(parentUid, token));
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // TODO: deep-link to the relevant student's status/logs screen.
    });
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
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
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

  Future<void> _saveTokenToFirestore(String parentUid) async {
    final token = await _messaging.getToken();
    if (token != null) await _updateToken(parentUid, token);
  }

  Future<void> _updateToken(String parentUid, String token) async {
    await FirebaseFirestore.instance.collection('parents').doc(parentUid).set({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
