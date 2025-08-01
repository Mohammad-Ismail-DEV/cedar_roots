import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cedar_roots/screens/chat.dart';
import 'package:cedar_roots/screens/group_chat.dart';
import 'package:cedar_roots/screens/connections.dart';
import 'package:cedar_roots/services/socket_service.dart';
import 'package:cedar_roots/components/chat_list_tile.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final SocketService _socketService = SocketService();
  List<Map<String, dynamic>> conversations = [];
  late SharedPreferences prefs;
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _socketService.socket.on('receive_message', (_) => _fetchMessages());
    _socketService.socket.on('receive_group_message', (_) => _fetchMessages());
    _socketService.socket.on('fetched_user_messages', (data) async {
      if (!mounted) return;
      if (data is List) {
        final parsed = List<Map<String, dynamic>>.from(data);
        setState(() => conversations = parsed);
        await _saveChatsToFile(parsed);
      }
    });
  }

  Future<String> _getChatCachePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/cached_conversations.json';
  }

  Future<void> _saveChatsToFile(List<Map<String, dynamic>> chats) async {
    try {
      final path = await _getChatCachePath();
      final file = File(path);
      await file.writeAsString(jsonEncode(chats));
    } catch (e) {
      print('❌ Error saving chats to file: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadChatsFromFile() async {
    try {
      final path = await _getChatCachePath();
      final file = File(path);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final decoded = jsonDecode(contents);
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      print('❌ Error loading chats from file: $e');
    }
    return [];
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt("user_id") ?? 0;

    // Load from cache first
    final cached = await _loadChatsFromFile();
    if (mounted) {
      setState(() => conversations = cached);
    }

    // Then fetch fresh data via socket
    await _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final userId = currentUserId;
    if (userId == 0) return;
    _socketService.socket.emit('fetch_user_messages', {"userId": userId});
  }

  @override
  void dispose() {
    _socketService.socket.off('fetched_user_messages');
    _socketService.socket.off('receive_message');
    _socketService.socket.off('receive_group_message');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Stack(
        children: [
          conversations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'No open chats',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final lastMsg = conversation['last_message'] ?? {};
                  final isGroup = conversation['type'] == 'group';
                  final isSentByMe = lastMsg['status'] == 'sent';
                  final content =
                      lastMsg['type'] == 'image'
                          ? '📷 image'
                          : lastMsg['content'] ?? '';

                  return ChatListTile(
                    name: conversation['name'],
                    content: content,
                    timestamp: lastMsg['sent_at'],
                    unreadCount: conversation['unread_count'] ?? 0,
                    isGroup: isGroup,
                    isSentByMe: isSentByMe,
                    status:
                        isSentByMe
                            ? (lastMsg['read_status'] == true
                                ? 'read'
                                : lastMsg['status'] ?? 'sending')
                            : '',
                    profilePic: conversation['profile_pic'],
                    onTap: () {
                      final route =
                          isGroup
                              ? MaterialPageRoute(
                                builder:
                                    (context) => GroupChatScreen(
                                      groupId: conversation['group_id'],
                                      groupName: conversation['name'],
                                    ),
                              )
                              : MaterialPageRoute(
                                builder:
                                    (context) => ChatScreen(
                                      receiverId: conversation['user_id'],
                                      name: conversation['name'],
                                    ),
                              );

                      Navigator.push(context, route).then((_) async {
                        await Future.delayed(Duration(milliseconds: 200));
                        _fetchMessages();
                      });
                    },
                  );
                },
              ),
          Positioned(
            bottom: 20,
            right: 20,
            child: SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF228B22).withOpacity(0.85),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConnectionsScreen(userId: currentUserId),
                    ),
                  );
                },
                child: const Icon(Icons.chat, size: 30, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
