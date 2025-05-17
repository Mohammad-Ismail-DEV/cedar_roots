import 'package:cedar_roots/main.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/screens/event_details.dart';
import 'package:cedar_roots/screens/post_details.dart';
import 'package:cedar_roots/services/socket_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await Firebase.initializeApp();
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) {
        SocketService().storeFcmToken(token);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showNotification(message.notification!, message.data);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) {
      // Can also be used to route when tapped while app is running
    });
  }

  void _handleMessageNavigation(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  if (userId == null) return;

  final type = message.data['notificationType'];
  switch (type) {
    case 'chat':
      final senderId = int.tryParse(message.data['senderId'] ?? '');
      final senderName = message.data['senderName'] ?? 'User';
      if (senderId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(receiverId: senderId, name: senderName),
          ),
        );
      }
      break;

    case 'comment':
    case 'like':
      final postId = int.tryParse(message.data['postId'] ?? '');
      if (postId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => PostDetailsScreen(postId: postId, userId: userId),
          ),
        );
      }
      break;

    case 'event_announcement':
    case 'new_event':
      final eventId = int.tryParse(message.data['eventId'] ?? '');
      if (eventId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(eventId: eventId, userId: userId),
          ),
        );
      }
      break;

    default:
      // No action
      break;
  }
}

  void _showNotification(
      RemoteNotification notification, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      platformDetails,
      payload: data['notificationType'], // optional use
    );
  }
}
