import 'package:cedar_roots/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  GroupChatScreen({required this.groupId});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messages = <Map<String, String>>[];
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _socketService = SocketService();

  String? userId;
  int currentPage = 1;
  bool loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
        !loadingMore) {
      currentPage++;
      _socketService.fetchGroupMessages(widget.groupId, currentPage);
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    _socketService.connect(userId!);

    _socketService.socket.on('receive_group_message', (data) {
      setState(() {
        _messages.insert(0, {
          'sender': data['senderId'],
          'content': data['content'],
        });
      });
    });

    _socketService.fetchGroupMessages(widget.groupId, 1);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && userId != null) {
      _socketService.sendGroupMessage(widget.groupId, userId!, text);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Group Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg['sender']!),
                  subtitle: Text(msg['content']!),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _textController)),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
