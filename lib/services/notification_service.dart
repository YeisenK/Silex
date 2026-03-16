import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../firebase_options.dart';

// top-level handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static const _channelId = 'silex_messages';
  static const _channelName = 'Messages';
  static const _channelDesc = 'Silex encrypted message notifications';

  static Future<void> initialize() async {
    // request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // setup local notifications (Android)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // foreground handler
    FirebaseMessaging.onMessage.listen((message) async {
      // check notification preferences
      final enabled = await StorageService.getKey('pref_notif_messages');
      if (enabled == 'false') return;
      await _showLocalNotification(message);
    });

    // register FCM token with backend
    await _registerToken();

    // listen for token refresh
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

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // check preferences
    final showPreviews = await StorageService.getKey('pref_notif_previews');
    final vibrate = await StorageService.getKey('pref_notif_vibrate');
    final sound = await StorageService.getKey('pref_notif_sound');

    final body = showPreviews == 'false'
        ? 'New encrypted message'
        : notification.body ?? 'New encrypted message';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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
  }
}
