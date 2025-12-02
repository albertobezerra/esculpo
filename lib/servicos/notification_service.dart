// lib/servicos/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  /// Inicializar notificações
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Lisbon')); // Portugal

      // Configurações Android
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurações iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Criar canal de notificação (Android)
      await _createNotificationChannel();

      // Solicitar permissões
      await _requestPermissions();

      // Configurar FCM
      await _setupFCM();

      _initialized = true;
      debugPrint('✅ NotificationService inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar NotificationService: $e');
    }
  }

  /// Criar canal de notificação (Android)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificações Importantes',
      description: 'Canal para notificações importantes do app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Solicitar permissões
  Future<bool> _requestPermissions() async {
    // iOS/Android 13+
    final fcmStatus = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (fcmStatus.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permissão de notificações concedida');
    } else {
      debugPrint('⚠️ Permissão de notificações negada');
    }

    // Android - Notificações exatas (alarmes)
    if (!kIsWeb) {
      try {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        if (exactAlarmStatus.isGranted) {
          debugPrint('✅ Permissão de alarmes exatos concedida');
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao solicitar permissão de alarme: $e');
      }
    }

    return fcmStatus.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Configurar Firebase Cloud Messaging
  Future<void> _setupFCM() async {
    try {
      // Token FCM
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      // Listener para atualização de token
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // Mensagens em foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Mensagens em background (app aberto)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } catch (e) {
      debugPrint('❌ Erro ao configurar FCM: $e');
    }
  }

  /// Salvar token no Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Token FCM salvo no Firestore');
    } catch (e) {
      debugPrint('❌ Erro ao salvar token: $e');
    }
  }

  /// Manipular mensagem em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '📬 Mensagem recebida (foreground): ${message.notification?.title}');

    showNotification(
      title: message.notification?.title ?? 'Nova notificação',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Manipular mensagem em background
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint(
        '📬 Mensagem recebida (background): ${message.notification?.title}');
  }

  /// Callback quando usuário toca na notificação
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('👆 Notificação tocada: ${response.payload}');
  }

  /// Mostrar notificação imediata
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificações Importantes',
      channelDescription: 'Canal para notificações importantes do app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🚫 Todas as notificações canceladas');
  }

  /// Verificar se notificações estão ativadas
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    final status = await Permission.notification.status;
    return status.isGranted;
  }
}

/// Handler para mensagens em background (precisa ser função top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Mensagem em background: ${message.notification?.title}');
}
