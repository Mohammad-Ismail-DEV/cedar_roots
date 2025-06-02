import 'dart:convert';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/screens/organization.dart';
import 'package:cedar_roots/screens/post_details.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'event_details.dart';
import 'profile.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoggedIn = false;
  List<dynamic> _notifications = [];
  String? _token;
  bool checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndFetch();
  }

  Future<String> _getNotificationCachePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/cached_notifications.json';
  }

  Future<void> _saveNotificationsToFile(List<dynamic> notifications) async {
    try {
      final path = await _getNotificationCachePath();
      final file = File(path);
      await file.writeAsString(jsonEncode(notifications));
    } catch (e) {
      print('❌ Error saving notifications cache: $e');
    }
  }

  Future<List<dynamic>> _loadNotificationsFromFile() async {
    try {
      final path = await _getNotificationCachePath();
      final file = File(path);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      print('❌ Error reading notifications cache: $e');
    }
    return [];
  }

  Future<void> _checkLoginStatusAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _token = prefs.getString('auth_token');

    if (!mounted) return;
    setState(() => _isLoggedIn = isLoggedIn);

    if (!_isLoggedIn || _token == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      if (!mounted) return;
      setState(() => checkingLogin = false);
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    // Load from file first
    final cached = await _loadNotificationsFromFile();
    if (mounted) {
      setState(() => _notifications = cached);
    }

    // Then fetch from API
    final res = await http.get(
      Uri.parse('http://13.50.2.82:3000/notifications'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => _notifications = data);
      await _saveNotificationsToFile(data);
    } else {
      print('❌ Failed to fetch notifications');
    }
  }

  Future<void> _markAsRead(int id) async {
    final res = await http.put(
      Uri.parse('http://13.50.2.82:3000/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (res.statusCode == 200 && mounted) {
      _fetchNotifications();
    }
  }

  Future<void> _deleteNotification(int id) async {
    final res = await http.delete(
      Uri.parse('http://13.50.2.82:3000/notifications/$id'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (res.statusCode == 200 && mounted) {
      setState(() {
        _notifications.removeWhere((n) => n['id'] == id);
      });
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notif) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null || !mounted) return;

    // Decode the `data` JSON string from DB
    Map<String, dynamic> data = {};
    try {
      data =
          notif['data'] is String
              ? jsonDecode(notif['data'])
              : Map<String, dynamic>.from(notif['data'] ?? {});
    } catch (e) {
      print('❌ Failed to parse notification data: $e');
      return;
    }

    final parsedData =
        notif['data'] is String
            ? jsonDecode(notif['data'])
            : Map<String, dynamic>.from(notif['data'] ?? {});

    final type = parsedData['notificationType'] ?? notif['type'];

    await _markAsRead(notif['id']);

    switch (type) {
      case 'chat':
        final senderId = int.tryParse(data['senderId'] ?? '');
        final senderName = data['senderName'] ?? 'User';
        if (senderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ChatScreen(receiverId: senderId, name: senderName),
            ),
          );
        }
        break;

      case 'comment':
      case 'like':
        final postId = int.tryParse(data['postId'] ?? '');
        if (postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PostDetailsScreen(postId: postId, userId: userId),
            ),
          );
        }
        break;

      case 'event_announcement':
      case 'new_event':
      case 'event_invite':
      case 'event_join':
        final eventId = int.tryParse(data['eventId'] ?? '');
        if (eventId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      EventDetailsScreen(eventId: eventId, userId: userId),
            ),
          );
        }
        break;

      case 'connection_request':
      case 'connection_accept':
        final targetId = int.tryParse(
          data['senderId'] ?? data['receiverId'] ?? '',
        );
        if (targetId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ProfileScreen(userId: targetId, isCurrentUser: false),
            ),
          );
        }
        break;

      case 'organization_invite':
      case 'organization_accept':
        final orgId = int.tryParse(data['organizationId'] ?? '');
        if (orgId != null) {
          // You should replace with your actual Organization screen:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OrganizationScreen(
                    organizationId: orgId,
                  ), // replace with your screen
            ),
          );
        }
        break;

      default:
        print('⚠️ Unhandled notification type: $type');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return checkingLogin
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
          appBar: AppBar(title: Text('Notifications')),
          body:
              _notifications.isEmpty
                  ? Center(child: Text('No notifications'))
                  : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['is_read'] == true;

                      return ListTile(
                        tileColor: isRead ? Colors.grey[200] : Colors.white,
                        title: Text(notif['message'] ?? 'Notification'),
                        subtitle: Text(notif['type'] ?? 'info'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              IconButton(
                                icon: Icon(Icons.done, color: Colors.green),
                                onPressed: () => _markAsRead(notif['id']),
                                tooltip: 'Mark as read',
                              ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNotification(notif['id']),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        onTap: () => _handleNotificationTap(notif),
                      );
                    },
                  ),
        );
  }
}
