import 'package:cedar_roots/screens/group_chat.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String? userId;
  List<Map<String, dynamic>> dummyConversations = [
    {'id': '1', 'name': 'Group A', 'type': 'group'},
    {'id': '2', 'name': 'John Doe', 'type': 'private'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: ListView.builder(
        itemCount: dummyConversations.length,
        itemBuilder: (context, index) {
          final conversation = dummyConversations[index];
          return ListTile(
            title: Text(conversation['name']),
            onTap: () {
              if (conversation['type'] == 'group') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            GroupChatScreen(groupId: conversation['id']),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ChatScreen(receiverId: conversation['id']),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
