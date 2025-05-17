import 'dart:convert';
import 'package:cedar_roots/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  List<Map<String, dynamic>> pendingMessages = [];
  int currentPage = 1;
  bool loadingMore = false;
  bool isReady = false;
  bool isInitialLoad = true;
  bool showScrollToBottom = false;
  int newMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _scrollController.addListener(_scrollListener);
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && pendingMessages.isNotEmpty) {
        for (var msg in pendingMessages) {
          _socketService.socket.emit("send_message", msg);
        }
        pendingMessages.clear();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _socketService.onMessageReceived = null;
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id') ?? 0;
    _socketService.connect(currentUserId);
    _socketService.socket.on('messages_seen_by_receiver', _handleSeenMessages);
    _socketService.socket.on('message_saved', _handleMessageSaved);
    _socketService.socket.on("message_delivered", _handleMessageDelivered);
    _socketService.onMessageReceived = _handleReceiveMessage;

    try {
      await _fetchMessages();
    } catch (e) {
      print('⚠️ Failed to fetch messages, loading from cache.');
      await _loadCachedMessages();
    }

    setState(() => isReady = true);
    _scrollToBottom();
  }

  Future<void> _loadCachedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('chat_${widget.receiverId}');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      setState(() {
        messages = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  void _handleMessageSaved(dynamic data) {
    final localId = data['local_id'];
    final realId = data['messageId'];
    if (!mounted) return;
    setState(() {
      for (var msg in messages) {
        if (msg['id'] == localId) {
          msg['id'] = realId;
          msg['read_status'] = "sent";
          break;
        }
      }
    });
  }

  void _handleSeenMessages(dynamic data) {
    if (!mounted) return;
    if (data['senderId'] == currentUserId) {
      final seenIds = List<int>.from(data['messageIds'] ?? []);
      setState(() {
        for (var msg in messages) {
          if (msg['status'] == 'sent' &&
              msg['read_status'] != "seen" &&
              seenIds.contains(msg['id'])) {
            msg['read_status'] = "seen";
          }
        }
      });
    }
  }

  void _handleReceiveMessage(dynamic data) {
    if (!mounted) return;
    if (data['sender_id'] == widget.receiverId ||
        data['receiver_id'] == widget.receiverId) {
      final newMsg = _mapMessage(data);
      setState(() => messages.add(newMsg));

      if (data['id'] != null) {
        _socketService.socket.emit("message_received", {
          "messageId": data['id'],
          "senderId": data['sender_id'],
          "receiverId": data['receiver_id'],
        });
      }

      final atBottom =
          _scrollController.hasClients &&
          _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 50;

      if (atBottom) {
        _scrollToBottom();
        _markMessagesAsRead();
        setState(() {
          showScrollToBottom = false;
          newMessagesCount = 0;
        });
      } else {
        setState(() {
          showScrollToBottom = true;
          newMessagesCount += 1;
        });
      }
    }
  }

  void _handleMessageDelivered(dynamic data) {
    if (!mounted) return;
    final deliveredId = data['messageId'];
    setState(() {
      for (var msg in messages) {
        if (msg['id'] == deliveredId) {
          msg['read_status'] = 'delivered';
          break;
        }
      }
    });
  }

  Future<void> _fetchMessages() async {
    setState(() => loadingMore = true);
    _socketService.socket.emit("fetch_messages", {
      "senderId": currentUserId,
      "receiverId": widget.receiverId,
      "page": currentPage,
    });

    _socketService.socket.once("fetched_messages", (data) async {
      if (!mounted) return;
      final fetched = List<Map<String, dynamic>>.from(data.map(_mapMessage));
      setState(() {
        messages.insertAll(0, fetched);
        loadingMore = false;
      });

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_${widget.receiverId}', jsonEncode(messages));

      if (isInitialLoad) {
        isInitialLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.offset <= 100 && !loadingMore) {
      currentPage++;
      _fetchMessages();
    }
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      _markMessagesAsRead();
      setState(() {
        showScrollToBottom = false;
        newMessagesCount = 0;
      });
    }
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

  void _markMessagesAsRead() {
    final unread =
        messages
            .where(
              (m) => m['status'] == 'received' && m['read_status'] != "seen",
            )
            .toList();
    if (unread.isEmpty) return;
    _socketService.socket.emit("mark_messages_as_read", {
      "senderId": widget.receiverId,
      "receiverId": currentUserId,
    });
    for (var msg in unread) {
      msg['read_status'] = "seen";
    }
    setState(() {});
  }

  void _sendMessage(String content, String type) async {
    final localId = DateTime.now().millisecondsSinceEpoch;
    final message = {
      "senderId": currentUserId,
      "receiverId": widget.receiverId,
      "content": content,
      "type": type,
      "local_id": localId,
    };

    final isOnline =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    if (isOnline) {
      _socketService.socket.emit("send_message", message);
    } else {
      pendingMessages.add(message);
    }

    setState(() {
      messages.add({
        ...message,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'sent',
        'read_status': 'sending',
        'type': type,
        'id': localId,
      });
    });

    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendMedia() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    for (var file in picked) {
      final fileUrl = await ApiServices().uploadFile(file);
      if (fileUrl != null) {
        _sendMessage(fileUrl, 'image');
      } else {
        return;
      }
    }
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
    if (msg['status'] != 'received' || msg['read_status'] == "seen")
      return false;
    return messages
        .sublist(0, index)
        .every((m) => m['read_status'] == "seen" || m['status'] == 'sent');
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
                            return Column(
                              children: [
                                if (_isNewDay(i))
                                  DaySeparator(
                                    formattedDate: _formatDate(msg['sent_at']),
                                  ),
                                if (_isUnreadSeparator(i))
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
}
