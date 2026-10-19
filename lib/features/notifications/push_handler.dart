import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../../core/session.dart';
import '../../data/push_service.dart';
import 'notification_router.dart';

final pushHandlerProvider = Provider<PushHandler>((ref) => PushHandler(ref));

/// Starts push notifications once someone signs in: registers the device token,
/// shows foreground notifications, and routes taps to the right screen.
final pushLifecycleProvider = Provider<void>((ref) {
  final handler = ref.watch(pushHandlerProvider);
  ref.listen<Session?>(sessionProvider, (_, session) {
    if (session != null) handler.start();
  }, fireImmediately: true);
});

class PushHandler {
  PushHandler(this._ref);

  final Ref _ref;
  final _local = FlutterLocalNotificationsPlugin();
  bool _listening = false;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  Future<void> start() async {
    if (PushService.platform == null) return;

    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    await _registerToken(await _fcm.getToken());

    if (_listening) return;
    _listening = true;

    _fcm.onTokenRefresh.listen(_registerToken);
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _route(Map<String, dynamic>.from(jsonDecode(payload) as Map));
      },
    );

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _route(initial.data);
  }

  Future<void> _registerToken(String? token) async {
    if (token == null) return;
    await _ref.read(pushServiceProvider).register(token);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _route(Map<String, dynamic> raw) {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final data = raw.map((k, v) => MapEntry(k, '$v'));
    final type = data['notificationType'];
    AppLog.d('open notification type=$type', 'push');
    if (type == null) return;
    openNotificationTarget(type: type, data: data, myUserId: userId);
  }
}
