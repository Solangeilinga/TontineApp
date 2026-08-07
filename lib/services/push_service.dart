// lib/services/push_service.dart
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// ⚠️ À COMPLÉTER : clé VAPID générée dans la console Firebase
// (Paramètres du projet → Cloud Messaging → Web configuration → "Générer
// une paire de clés"). Uniquement utilisée sur le web — ignorée sur
// Android/iOS (le paramètre vapidKey de getToken() y est simplement inerte).
const _webVapidKey = 'REMPLACER_PAR_LA_CLE_VAPID';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message background: ${message.messageId}');
}

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();
  final _api = ApiService();

  static const _channelId = 'tontineapp_channel';
  static const _channelName = 'MaTontine';

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Notifications refusées');
      return;
    }

    // flutter_local_notifications ne supporte pas le web correctement (pas
    // de canal/permission natifs équivalents) — et c'est de toute façon
    // inutile ici : sur le web, c'est le service worker
    // (web/firebase-messaging-sw.js) qui affiche nativement la notification
    // via l'API Notification du navigateur, pas ce plugin.
    if (!kIsWeb) {
      // Initialiser notifications locales
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifs.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tappée: ${details.payload}');
        },
      );

      // ── Créer le canal Android — version compatible
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notifications MaTontine',
        importance: Importance.high,
      );

      await _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await _refreshToken();
    _messaging.onTokenRefresh.listen(_sendTokenToServer);

    debugPrint('✅ Push notifications initialisées');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifs.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifications MaTontine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<void> _refreshToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      if (token != null) await _sendTokenToServer(token);
    } catch (e) {
      debugPrint('❌ Erreur token FCM: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _api.dio.put('/notifications/fcm-token', data: {
        'fcmToken': token,
      });
      debugPrint('✅ Token FCM envoyé');
    } catch (e) {
      debugPrint('❌ Erreur envoi token: $e');
    }
  }
}