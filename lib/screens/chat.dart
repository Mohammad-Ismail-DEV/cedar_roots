import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cedar_roots/services/socket_service.dart';
import 'package:cedar_roots/components/chat_message_bubble.dart';
import 'package:cedar_roots/components/day_separator.dart';
import 'package:cedar_roots/components/new_message_indicator.dart';
import 'package:cedar_roots/components/message_input_field.dart';
import 'package:cedar_roots/components/scroll_to_bottom_button.dart';
import 'package:cedar_roots/components/image_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String name;

  ChatScreen({required this.receiverId, required this.name});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  late int currentUserId;
  List<Map<String, dynamic>> messages = [];
  int currentPage = 1;
  bool loadingMore = false;
  bool isReady = false;
  bool isInitialLoad = true;
  bool showScrollToBottom = false;
  int? unreadIndex;
  int newMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _scrollController.addListener(_scrollListener);
    _socketService.socket.on('receive_message', _handleReceiveMessage);
    _socketService.socket.on('messages_seen_by_receiver', _handleSeenMessages);
    _socketService.socket.on('message_saved', _handleMessageSaved);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _socketService.socket.off('receive_message', _handleReceiveMessage);
    _socketService.socket.off('messages_seen_by_receiver', _handleSeenMessages);
    _socketService.socket.off('message_saved', _handleMessageSaved);
    super.dispose();
  }

  void _handleMessageSaved(dynamic data) {
    final localId = data['local_id'];
    final realId = data['messageId'];
    if (!mounted) return;
    setState(() {
      for (var msg in messages) {
        if (msg['id'] == localId) {
          msg['id'] = realId;
          break;
        }
      }
    });
  }

  void _handleReceiveMessage(dynamic data) {
    if (!mounted) return;
    if (data['sender_id'] == widget.receiverId ||
        data['receiver_id'] == widget.receiverId) {
      final newMsg = _mapMessage(data);
      setState(() => messages.add(newMsg));

      final atBottom =
          _scrollController.hasClients &&
          _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 50;

      if (atBottom) {
        _scrollToBottom();
        _markMessagesAsRead();
        unreadIndex = null;
      } else {
        setState(() {
          showScrollToBottom = true;
          newMessagesCount += 1;
        });
      }
    }
  }

  void _handleSeenMessages(dynamic data) {
    if (!mounted) return;
    if (data['senderId'] == currentUserId) {
      final seenIds = List<int>.from(data['messageIds'] ?? []);
      setState(() {
        for (var msg in messages) {
          if (msg['status'] == 'sent' &&
              !msg['read_status'] &&
              seenIds.contains(msg['id'])) {
            msg['read_status'] = true;
          }
        }
      });
    }
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id') ?? 0;
    _socketService.connect(currentUserId);
    await _fetchMessages();
    setState(() => isReady = true);
    _scrollToBottom();
  }

  Future<void> _fetchMessages() async {
    setState(() => loadingMore = true);
    _socketService.socket.emit("fetch_messages", {
      "senderId": currentUserId,
      "receiverId": widget.receiverId,
      "page": currentPage,
    });

    _socketService.socket.once("fetched_messages", (data) {
      if (!mounted) return;
      final fetched = List<Map<String, dynamic>>.from(data.map(_mapMessage));
      setState(() {
        messages.insertAll(0, fetched);
        loadingMore = false;
      });

      if (isInitialLoad) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToFirstUnread(),
        );
        isInitialLoad = false;
      }
    });
  }

  Map<String, dynamic> _mapMessage(dynamic m) => {
    'id': m['id'],
    'content': m['content'],
    'sent_at': m['sent_at'],
    'status': m['sender_id'] == currentUserId ? 'sent' : 'received',
    'read_status': m['read_status'] ?? false,
    'type': m['type'] ?? 'text',
  };

  void _scrollListener() {
    if (_scrollController.offset <= 0 && !loadingMore) {
      currentPage++;
      _fetchMessages();
    }
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      _markMessagesAsRead();
      unreadIndex = null;
    }
    setState(() => showScrollToBottom = !atBottom);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToFirstUnread() {
    if (!_scrollController.hasClients) return;
    final index = messages.indexWhere(
      (m) => m['status'] == 'received' && !m['read_status'],
    );
    unreadIndex = index != -1 ? index : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (unreadIndex != null) {
        _scrollController.jumpTo(unreadIndex! * 100.0);
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _markMessagesAsRead() {
    final unread =
        messages
            .where((m) => m['status'] == 'received' && !m['read_status'])
            .toList();
    if (unread.isEmpty) return;
    _socketService.socket.emit("mark_messages_as_read", {
      "senderId": widget.receiverId,
      "receiverId": currentUserId,
    });
    for (var msg in unread) {
      msg['read_status'] = true;
    }
    setState(() {});
  }

  void _sendMessage(String content, String type) {
    final localId = DateTime.now().millisecondsSinceEpoch;
    _textController.clear();
    final message = {
      "senderId": currentUserId,
      "receiverId": widget.receiverId,
      "content": content,
      "type": type,
      "local_id": localId,
    };
    _socketService.socket.emit("send_message", message);
    setState(() {
      messages.add({
        ...message,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
        'read_status': false,
        'id': localId,
      });
    });
    _scrollToBottom();
  }

  Future<void> _pickAndSendMedia() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    for (var file in picked) {
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("http://13.48.155.59:3000/upload"),
      );
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await req.send();
      final resBody = await response.stream.bytesToString();
      final fileUrl = json.decode(resBody)['url'];
      _sendMessage(fileUrl, 'image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body:
          isInitialLoad
              ? Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Column(
                    children: [
                      if (loadingMore)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = messages[i];
                            final isMe = msg['status'] == 'sent';
                            final type = msg['type'] ?? 'text';
                            final unreadSeparator = _isUnreadSeparator(i);

                            return Column(
                              children: [
                                if (_isNewDay(i))
                                  DaySeparator(
                                    formattedDate: _formatDate(msg['sent_at']),
                                  ),
                                if (unreadSeparator)
                                  const NewMessageIndicator(),
                                ChatMessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  onImageTap:
                                      type == 'image'
                                          ? () {
                                            final imageUrls =
                                                messages
                                                    .where(
                                                      (m) =>
                                                          m['type'] == 'image',
                                                    )
                                                    .map<String>(
                                                      (m) =>
                                                          m['content']
                                                              as String,
                                                    )
                                                    .toList();
                                            final initialIndex = imageUrls
                                                .indexOf(msg['content']);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ImagePreviewScreen(
                                                      imageUrls: imageUrls,
                                                      initialIndex:
                                                          initialIndex,
                                                    ),
                                              ),
                                            );
                                          }
                                          : null,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Divider(height: 1),
                      MessageInputField(
                        controller: _textController,
                        onSend:
                            () => _sendMessage(
                              _textController.text.trim(),
                              'text',
                            ),
                        onImagePick: _pickAndSendMedia,
                        isEnabled: isReady,
                      ),
                    ],
                  ),
                  if (showScrollToBottom)
                    ScrollToBottomButton(
                      newMessagesCount: newMessagesCount,
                      onPressed: _scrollToBottom,
                    ),
                ],
              ),
    );
  }

  String _formatDate(String time) =>
      DateFormat('MMMM d, y').format(DateTime.parse(time).toLocal());

  bool _isNewDay(int i) {
    if (i == 0) return true;
    final d1 = DateTime.parse(messages[i]['sent_at']).toLocal();
    final d2 = DateTime.parse(messages[i - 1]['sent_at']).toLocal();
    return d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
  }

  bool _isUnreadSeparator(int index) {
    final msg = messages[index];
    if (msg['status'] != 'received' || msg['read_status']) return false;
    return messages
        .sublist(0, index)
        .every((m) => m['read_status'] || m['status'] == 'sent');
  }
}
