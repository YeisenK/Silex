import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  if (notification == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  const androidDetails = AndroidNotificationDetails(
    'silex_messages',
    'Messages',
    channelDescription: 'Silex encrypted message notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    notification.title ?? 'Silex',
    notification.body ?? 'New encrypted message',
    const NotificationDetails(android: androidDetails),
  );
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'silex_messages',
            'Messages',
            description: 'Silex encrypted message notifications',
            importance: Importance.high,
          ),
        );

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      final enabled = await StorageService.getKey('pref_notif_messages');
      if (enabled == 'false') return;

      final notification = message.notification;
      if (notification == null) return;

      final showPreviews =
          await StorageService.getKey('pref_notif_previews');
      final vibrate = await StorageService.getKey('pref_notif_vibrate');
      final sound = await StorageService.getKey('pref_notif_sound');

      final body = showPreviews == 'false'
          ? 'New encrypted message'
          : notification.body ?? 'New encrypted message';

      final androidDetails = AndroidNotificationDetails(
        'silex_messages',
        'Messages',
        channelDescription: 'Silex encrypted message notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: vibrate != 'false',
        playSound: sound != 'false',
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title ?? 'Silex',
        body,
        NotificationDetails(android: androidDetails),
      );
    });

    await _registerToken();
    _messaging.onTokenRefresh.listen((_) => _registerToken());
  }

  static Future<void> _registerToken() async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;

      final jwt = await StorageService.getJwt();
      if (jwt == null) return;

      await _dio.post(
        '/users/fcm-token',
        data: {
          'fcmToken': fcmToken,
          'deviceId': 'default',
        },
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
    } catch (_) {}
  }
}