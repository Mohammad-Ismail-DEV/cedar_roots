import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../data/chat_repository.dart';
import '../../data/media_repository.dart';
import '../../models/message.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.newMessages = 0,
    this.firstUnreadId,
    this.otherTyping = false,
    this.error,
  });

  /// Oldest first.
  final List<Message> messages;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// Messages that arrived while the user was scrolled up.
  final int newMessages;

  /// Where the "New Messages" divider goes.
  final int? firstUnreadId;
  final bool otherTyping;
  final String? error;

  ChatState copyWith({
    List<Message>? messages,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? newMessages,
    int? firstUnreadId,
    bool? otherTyping,
    String? error,
    bool clearError = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    newMessages: newMessages ?? this.newMessages,
    firstUnreadId: firstUnreadId ?? this.firstUnreadId,
    otherTyping: otherTyping ?? this.otherTyping,
    error: clearError ? null : (error ?? this.error),
  );
}

int _lastLocalId = 0;

/// Unique even when two messages are sent within the clock's resolution.
int _nextLocalId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _lastLocalId = now > _lastLocalId ? now : _lastLocalId + 1;
  return _lastLocalId;
}

/// State of one conversation. The argument is the other user's id.
final chatControllerProvider = NotifierProvider.autoDispose
    .family<ChatController, ChatState, int>(ChatController.new);

class ChatController extends AutoDisposeFamilyNotifier<ChatState, int> {
  late ChatRepository _chat;
  late int _me;
  int _page = 1;
  bool _atBottom = true;
  Timer? _typingTimer;
  bool _disposed = false;

  /// Photos being uploaded, by local id: completing one cancels that upload.
  final _uploads = <int, Completer<void>>{};
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);

  int get _other => arg;

  @override
  ChatState build(int arg) {
    _chat = ref.read(chatRepositoryProvider);
    _me = ref.read(currentUserIdProvider) ?? 0;
    // build() runs again on ref.invalidate (the Retry button), so reset per-build state.
    _page = 1;
    _atBottom = true;

    final subscriptions = <StreamSubscription<dynamic>>[
      _chat.incoming.listen(_onIncoming),
      _chat.saved.listen(_onSaved),
      _chat.delivered.listen(_onDelivered),
      _chat.seen.listen(_onSeen),
      _chat.failed.listen(_onFailed),
      _chat.typing.where((id) => id == arg).listen(_onTyping),
      _chat.connection
          .where((connected) => connected)
          .listen((_) => _syncLatest()),
    ];
    ref.onDispose(() {
      _disposed = true;
      for (final upload in _uploads.values) {
        if (!upload.isCompleted) upload.complete();
      }
      for (final s in subscriptions) {
        s.cancel();
      }
      _typingTimer?.cancel();
    });

    final cached = _chat.cachedHistory(arg);
    Future.microtask(_loadInitial);
    return ChatState(messages: cached, loading: cached.isEmpty);
  }

  // ---- loading

  Future<void> _loadInitial() async {
    try {
      final fetched = await _chat.fetchHistory(_other);
      _page = 1;
      // Keep cached older messages (so the list doesn't shrink and jump) but let the
      // server's copy win for anything it returned.
      final merged = _mergeConfirmed(state.messages, fetched);
      state = state.copyWith(
        messages: [...merged, ...state.messages.where(_isUnconfirmed)],
        loading: false,
        hasMore: fetched.length >= ChatRepository.pageSize,
        firstUnreadId: _firstUnread(merged),
        clearError: true,
      );
      _persist();
      if (_atBottom) markRead();
    } catch (e) {
      state = state.copyWith(loading: false, error: errorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final older = await _chat.fetchHistory(_other, page: _page + 1);
      _page++;
      final known = state.messages.map((m) => m.id).toSet();
      state = state.copyWith(
        messages: [
          ...older.where((m) => !known.contains(m.id)),
          ...state.messages,
        ],
        loadingMore: false,
        hasMore: older.length >= ChatRepository.pageSize,
      );
      _persist();
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  /// After a reconnect: pull the newest page to catch up on anything missed.
  Future<void> _syncLatest() async {
    if (state.loading) return;
    try {
      final latest = await _chat.fetchHistory(_other);
      state = state.copyWith(
        messages: [
          ..._mergeConfirmed(state.messages, latest),
          ...state.messages.where(_isUnconfirmed),
        ],
      );
      _persist();
    } catch (_) {
      // The next reconnect will try again.
    }
  }

  int? _firstUnread(List<Message> messages) {
    for (final m in messages) {
      if (m.senderId == _other && m.status != MessageStatus.seen) return m.id;
    }
    return null;
  }

  // ---- sending

  void sendText(String text) {
    final content = text.trim();
    if (content.isNotEmpty) _send(content, 'text');
  }

  /// Shows the photo in the chat straight away, uploads it, then sends the message.
  void sendLocalImage(String path) {
    final localId = _nextLocalId();
    final message = Message(
      id: localId,
      localId: localId,
      senderId: _me,
      receiverId: _other,
      content: path,
      type: 'image',
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    state = state.copyWith(messages: [...state.messages, message]);
    _upload(message);
  }

  Future<void> _upload(Message message) async {
    final localId = message.localId!;
    final cancel = Completer<void>();
    _uploads[localId] = cancel;
    try {
      final url = await ref
          .read(mediaRepositoryProvider)
          .uploadImage(XFile(message.content), abortTrigger: cancel.future);
      if (_disposed || cancel.isCompleted) return;
      _update(localId, (m) => m.copyWith(content: url));
      _chat.send(
        receiverId: _other,
        content: url,
        localId: localId,
        type: 'image',
      );
    } on UploadCancelled {
      // The user removed the photo; cancelSend already took it out of the list.
    } catch (_) {
      if (!_disposed && !cancel.isCompleted) {
        _update(localId, (m) => m.copyWith(status: MessageStatus.failed));
      }
    } finally {
      _uploads.remove(localId);
    }
  }

  void _update(int localId, Message Function(Message) change) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages) m.localId == localId ? change(m) : m,
      ],
    );
  }

  /// Stops an upload in progress, or discards a photo that failed to send.
  void cancelSend(Message message) {
    final upload = _uploads[message.localId];
    if (upload != null && !upload.isCompleted) upload.complete();
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != message.id).toList(),
    );
  }

  void retry(Message failed) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != failed.id).toList(),
    );
    if (failed.isLocal) {
      sendLocalImage(failed.content);
    } else {
      _send(failed.content, failed.type);
    }
  }

  void _send(String content, String type) {
    final localId = _nextLocalId();
    final message = Message(
      id: localId,
      localId: localId,
      senderId: _me,
      receiverId: _other,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    state = state.copyWith(messages: [...state.messages, message]);
    _chat.send(
      receiverId: _other,
      content: content,
      localId: localId,
      type: type,
    );
  }

  /// Call as the user types; tells the other side at most every 2 seconds.
  void notifyTyping() {
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < const Duration(seconds: 2)) return;
    _lastTypingSent = now;
    _chat.sendTyping(_other);
  }

  // ---- reading

  /// The screen reports whether the newest message is in view.
  void setAtBottom(bool atBottom) {
    _atBottom = atBottom;
    if (atBottom) markRead();
  }

  void markRead() {
    final hasUnseen = state.messages.any(
      (m) => m.senderId == _other && m.status != MessageStatus.seen,
    );
    if (!hasUnseen && state.newMessages == 0) return;

    if (hasUnseen) _chat.markSeen(_other);
    state = state.copyWith(
      newMessages: 0,
      messages: [
        for (final m in state.messages)
          m.senderId == _other ? m.copyWith(status: MessageStatus.seen) : m,
      ],
    );
  }

  // ---- socket events

  void _onIncoming(Message message) {
    if (message.senderId != _other) return;
    if (state.messages.any((m) => m.id == message.id)) return;

    state = state.copyWith(
      messages: [...state.messages, message],
      otherTyping: false,
      firstUnreadId: state.firstUnreadId ?? (_atBottom ? null : message.id),
      newMessages: _atBottom ? null : state.newMessages + 1,
    );
    if (_atBottom) markRead();
    _persist();
  }

  void _onSaved(MessageSaved saved) {
    final index = state.messages.indexWhere((m) => m.localId == saved.localId);
    if (index < 0) return;

    final updated = [...state.messages];
    updated[index] = updated[index].copyWith(
      id: saved.messageId,
      status: MessageStatus.sent,
    );
    state = state.copyWith(messages: updated);
    _persist();
  }

  void _onDelivered(int messageId) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.id == messageId && m.status == MessageStatus.sent
              ? m.copyWith(status: MessageStatus.delivered)
              : m,
      ],
    );
  }

  void _onSeen(MessagesSeen seen) {
    if (seen.byUserId != _other) return;
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          seen.messageIds.contains(m.id)
              ? m.copyWith(status: MessageStatus.seen)
              : m,
      ],
    );
    _persist();
  }

  void _onFailed(MessageFailed failed) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          m.localId != null &&
                  m.localId == failed.localId &&
                  m.status == MessageStatus.sending
              ? m.copyWith(status: MessageStatus.failed)
              : m,
      ],
    );
  }

  void _onTyping(int _) {
    state = state.copyWith(otherTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      state = state.copyWith(otherTyping: false);
    });
  }

  // ---- helpers

  /// Union of the confirmed messages in [current] and [server], oldest first.
  List<Message> _mergeConfirmed(List<Message> current, List<Message> server) {
    final byId = {
      for (final m in current.where((m) => !_isUnconfirmed(m))) m.id: m,
    };
    for (final m in server) {
      byId[m.id] = m;
    }
    return byId.values.toList()..sort(_byTime);
  }

  bool _isUnconfirmed(Message m) =>
      m.status == MessageStatus.sending || m.status == MessageStatus.failed;

  int _byTime(Message a, Message b) {
    final byDate = a.sentAt.compareTo(b.sentAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  void _persist() => _chat.saveHistory(_other, state.messages);
}
