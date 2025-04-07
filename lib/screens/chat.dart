import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId; // The user you're chatting with

  ChatScreen({required this.receiverId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  int currentPage = 1;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_handleScroll);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id') ?? '';

    _socketService.connect(currentUserId);

    _socketService.socket.on('receive_message', (data) {
      if (data['sender_id'].toString() == widget.receiverId ||
          data['receiver_id'].toString() == widget.receiverId) {
        setState(() {
          messages.insert(0, data); // Add message to top for reverse list
        });
      }
    });

    _fetchMessages();
  }

  void _fetchMessages() {
    _socketService.fetchMessages(currentUserId, widget.receiverId, currentPage).then((newMessages) {
      setState(() {
        messages.addAll(newMessages);
      });
    });
  }

  void _handleScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      currentPage++;
      _fetchMessages();
    }
  }

  void _sendMessage() {
    String content = _textController.text.trim();
    if (content.isNotEmpty) {
      _socketService.sendMessage(currentUserId, widget.receiverId, content);
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
      appBar: AppBar(title: Text("Chat with ${widget.receiverId}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg['sender_id'].toString() == currentUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
