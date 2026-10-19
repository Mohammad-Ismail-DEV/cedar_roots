import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/photo_crop.dart';
import '../../core/providers.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../data/media_repository.dart';
import '../../models/message.dart';
import 'chat_controller.dart';
import 'image_preview_screen.dart';
import 'widgets/chat_chips.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/message_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.receiverId, required this.name});

  final int receiverId;
  final String name;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // The list is reversed, so scroll offset 0 is the newest message.
  final _scroll = ScrollController();
  final _text = TextEditingController();
  bool _atBottom = true;
  bool _uploading = false;

  ChatController get _controller =>
      ref.read(chatControllerProvider(widget.receiverId).notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;

    final atBottom = position.pixels <= 50;
    if (atBottom != _atBottom) {
      setState(() => _atBottom = atBottom);
      _controller.setAtBottom(atBottom);
    }
    if (position.pixels >= position.maxScrollExtent - 100) {
      _controller.loadMore();
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendText() {
    _controller.sendText(_text.text);
    _text.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImages() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      for (final original in picked) {
        var file = original;
        // Each photo goes through the crop screen first (not available on web).
        if (!kIsWeb) {
          final cropped = await cropPhoto(original.path);
          if (cropped == null) continue;
          file = XFile(cropped.path);
        }
        final url = await ref.read(mediaRepositoryProvider).uploadImage(file);
        _controller.sendImage(url);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  bool _isNewDay(List<Message> messages, int index) {
    if (index == 0) return true;
    final a = messages[index].sentAt;
    final b = messages[index - 1].sentAt;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  void _openImage(List<Message> messages, Message tapped) {
    final urls = [
      for (final m in messages)
        if (m.isImage) m.content,
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ImagePreviewScreen(
              imageUrls: urls,
              initialIndex: urls.indexOf(tapped.content),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.receiverId;
    final chat = ref.watch(chatControllerProvider(id));
    final me = ref.watch(currentUserIdProvider) ?? 0;
    final connected = ref.watch(socketConnectedProvider).valueOrNull ?? true;

    // Jump to the newest message when I send one.
    ref.listen(chatControllerProvider(id).select((s) => s.messages.length), (
      previous,
      next,
    ) {
      final last = ref.read(chatControllerProvider(id)).messages.lastOrNull;
      if (next > (previous ?? 0) && last != null && last.senderId == me) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final messages = chat.messages;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name),
            if (chat.otherTyping)
              const Text('typing…', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!connected)
            Container(
              width: double.infinity,
              color: Colors.orange[200],
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text('Connecting…', textAlign: TextAlign.center),
            ),
          Expanded(child: _buildMessages(chat, messages, me)),
          if (_uploading) const LinearProgressIndicator(minHeight: 3),
          const Divider(height: 1),
          MessageInputField(
            controller: _text,
            onSend: _sendText,
            onImagePick: _uploading ? null : _pickAndSendImages,
            onChanged: (_) => _controller.notifyTyping(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatState chat, List<Message> messages, int me) {
    if (chat.loading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty) {
      return Center(
        child:
            chat.error != null
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(chat.error!),
                    TextButton(
                      onPressed:
                          () => ref.invalidate(
                            chatControllerProvider(widget.receiverId),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                )
                : const Text('No messages yet'),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          reverse: true,
          controller: _scroll,
          itemCount: messages.length + (chat.loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final index = messages.length - 1 - i;
            final message = messages[index];
            return Column(
              children: [
                if (_isNewDay(messages, index))
                  DaySeparator(
                    formattedDate: DateFormat(
                      'MMMM d, y',
                    ).format(message.sentAt),
                  ),
                if (message.id == chat.firstUnreadId)
                  const NewMessageIndicator(),
                ChatMessageBubble(
                  message: message,
                  isMe: message.isMine(me),
                  onImageTap:
                      message.isImage
                          ? () => _openImage(messages, message)
                          : null,
                  onRetry: () => _controller.retry(message),
                ),
              ],
            );
          },
        ),
        if (!_atBottom)
          ScrollToBottomButton(
            newMessagesCount: chat.newMessages,
            onPressed: _scrollToBottom,
          ),
      ],
    );
  }
}
