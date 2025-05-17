import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'event_details.dart';
import 'profile.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoggedIn = false;
  List<dynamic> _notifications = [];
  String? _token;
  int? _userId;
  bool checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndFetch();
  }

  Future<void> _checkLoginStatusAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _token = prefs.getString('auth_token');
    _userId = prefs.getInt('user_id');

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
    final res = await http.get(
      Uri.parse('http://13.50.2.82:3000/notifications'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      setState(() {
        _notifications = jsonDecode(res.body);
      });
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

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final type = notif['type'];
    final data = notif;

    _markAsRead(notif['id']);

    switch (type) {
      case 'comment':
      case 'like':
        if (data['postId'] != null) {
          // Uncomment and implement when PostDetailsScreen is ready
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => PostDetailsScreen(postId: int.parse(data['postId'])),
          //   ),
          // );
        }
        break;
      case 'connection_request':
      case 'connection_accept':
        if (data['senderId'] != null || data['receiverId'] != null) {
          final targetId = int.tryParse(data['senderId'] ?? data['receiverId']);
          if (targetId != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: targetId),
              ),
            );
          }
        }
        break;
      case 'event_invite':
      case 'event_join':
        if (data['eventId'] != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EventDetailsScreen(
                    userId: _userId ?? 1,
                    eventId: int.parse(data['eventId']),
                  ),
            ),
          );
        }
        break;
      default:
        print('Unhandled notification type: $type');
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
