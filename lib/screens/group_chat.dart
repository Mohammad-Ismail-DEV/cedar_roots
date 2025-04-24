import 'package:cedar_roots/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupChatScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  GroupChatScreen({required this.groupId, required this.groupName});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messages = <Map<String, dynamic>>[];
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _socketService = SocketService();
  late SharedPreferences prefs;

  int currentPage = 1;
  bool loadingMore = false;
  bool allLoaded = false;

  
  // Initialize SharedPreferences
  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {}); // Trigger rebuild after prefs and messages are loaded
  }

  @override
  void initState() {
    super.initState();
    _initializePreferences();

    _socketService.connect(prefs.getInt("user_id")!);
    _scrollController.addListener(_scrollListener);
    _fetchMessages();

    _socketService.socket.on('receive_group_message', (data) {
      if (data['group_id'] == widget.groupId) {
        setState(() {
          _messages.insert(0, {
            'sender_name': data['sender_name'],
            'content': data['content'],
            'sent_at': data['sent_at'],
          });
        });
      }
    });
  }

  void _fetchMessages() {
    _socketService.socket.emit('fetch_group_messages', {
      'groupId': widget.groupId,
      'page': currentPage,
      'limit': 20,
    });

    _socketService.socket.on('fetched_group_messages', (data) {
      if (data is List && data.isNotEmpty) {
        setState(() {
          _messages.addAll(data.reversed.map((msg) => {
                'sender_name': msg['sender_name'],
                'content': msg['content'],
                'sent_at': msg['sent_at'],
              }));
          loadingMore = false;
        });
      } else {
        setState(() {
          allLoaded = true;
          loadingMore = false;
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
        !loadingMore &&
        !allLoaded) {
      loadingMore = true;
      currentPage++;
      _fetchMessages();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _socketService.sendGroupMessage(
        widget.groupId,
        prefs.getInt("user_id")!,
        text,
      );
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    // _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final time = DateTime.tryParse(msg['sent_at'] ?? '')?.toLocal();
                final formattedTime = time != null
                    ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                    : '';

                return ListTile(
                  title: Text(msg['sender_name'] ?? 'Unknown'),
                  subtitle: Text('${msg['content']} - $formattedTime'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
