import 'package:cedar_roots/main.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/services/socket_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await Firebase.initializeApp();
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      print(token);
      if (token != null) {
        SocketService().storeFcmToken(token);
      }

      // Foreground notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showNotification(message.notification!);
        }
      });

      // App in background, and user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

      // App launched from terminated state by tapping notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final senderId = int.tryParse(message.data['senderId'] ?? '');
    final senderName = message.data['senderName'] ?? 'User';

    if (senderId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(receiverId: senderId, name: senderName),
        ),
      );
    }
  }

  void _showNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }
}
