import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/local_cache.dart';
import '../core/providers.dart';
import '../core/socket_client.dart';
import '../models/json_helpers.dart';
import '../models/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    socket: ref.watch(socketClientProvider),
    cache: ref.watch(localCacheProvider),
  ),
);

class MessageSaved {
  const MessageSaved({required this.localId, required this.messageId});
  final int? localId;
  final int messageId;
}

class MessagesSeen {
  const MessagesSeen({required this.byUserId, required this.messageIds});

  /// The user who read the messages.
  final int byUserId;
  final Set<int> messageIds;
}

class MessageFailed {
  const MessageFailed({required this.localId, required this.error});
  final int? localId;
  final String error;
}

/// All chat traffic. The server owns message state; this class translates the
/// socket protocol into typed streams and requests.
class ChatRepository {
  ChatRepository({required SocketClient socket, required LocalCache cache})
    : _socket = socket,
      _cache = cache;

  final SocketClient _socket;
  final LocalCache _cache;

  static const pageSize = 20;

  Stream<Message> get incoming =>
      _socket.on('receive_message').map((d) => Message.fromJson(asMap(d)!));

  Stream<MessageSaved> get saved => _socket.on('message_saved').map((d) {
    final map = asMap(d)!;
    return MessageSaved(
      localId: asIntOrNull(map['local_id']),
      messageId: asInt(map['messageId']),
    );
  });

  Stream<int> get delivered =>
      _socket.on('message_delivered').map((d) => asInt(asMap(d)!['messageId']));

  /// Messages I sent that the other user has now seen.
  Stream<MessagesSeen> get seen => _socket.on('messages_seen_by_receiver').map((
    d,
  ) {
    final map = asMap(d)!;
    return MessagesSeen(
      byUserId: asInt(map['receiverId']),
      messageIds: (map['messageIds'] as List? ?? const []).map(asInt).toSet(),
    );
  });

  Stream<MessageFailed> get failed => _socket.on('message_failed').map((d) {
    final map = asMap(d)!;
    return MessageFailed(
      localId: asIntOrNull(map['local_id']),
      error: '${map['error']}',
    );
  });

  Stream<int> get typing =>
      _socket.on('user_typing').map((d) => asInt(asMap(d)!['senderId']));

  Stream<bool> get connection => _socket.connection;

  // ---- conversations

  List<Conversation>? cachedConversations() {
    final cached = _cache.read('conversations');
    return cached == null
        ? null
        : asMapList(cached).map(Conversation.fromJson).toList();
  }

  Future<List<Conversation>> fetchConversations() async {
    await _socket.whenConnected();
    final data = await _socket.request(
      'fetch_user_messages',
      const {},
      responseEvent: 'fetched_user_messages',
    );
    if (data is Map && data['error'] != null) {
      throw SocketRequestException('${data['error']}');
    }
    final list = asMapList(data);
    await _cache.write('conversations', list);
    return list.map(Conversation.fromJson).toList();
  }

  // ---- history

  List<Message> cachedHistory(int otherUserId) =>
      asMapList(
        _cache.read('chat:$otherUserId'),
      ).map(Message.fromJson).toList();

  Future<void> saveHistory(int otherUserId, List<Message> messages) {
    final confirmed =
        messages
            .where(
              (m) =>
                  m.status != MessageStatus.sending &&
                  m.status != MessageStatus.failed,
            )
            .toList();
    final recent =
        confirmed.length > 100
            ? confirmed.sublist(confirmed.length - 100)
            : confirmed;
    return _cache.write(
      'chat:$otherUserId',
      recent.map((m) => m.toJson()).toList(),
    );
  }

  /// One page of history, oldest message first. Page 1 is the newest.
  Future<List<Message>> fetchHistory(int otherUserId, {int page = 1}) async {
    await _socket.whenConnected();
    final data = await _socket.request(
      'fetch_messages',
      {'receiverId': otherUserId, 'page': page, 'limit': pageSize},
      responseEvent: 'fetched_messages',
      errorEvent: 'fetched_messages_error',
    );
    return asMapList(data).map(Message.fromJson).toList();
  }

  // ---- actions

  void send({
    required int receiverId,
    required String content,
    required int localId,
    String type = 'text',
  }) => _socket.emit('send_message', {
    'receiverId': receiverId,
    'content': content,
    'type': type,
    'local_id': localId,
  });

  void acknowledgeDelivery(int messageId) =>
      _socket.emit('message_received', {'messageId': messageId});

  void markSeen(int authorId) =>
      _socket.emit('mark_messages_as_read', {'senderId': authorId});

  void sendTyping(int receiverId) =>
      _socket.emit('typing', {'receiverId': receiverId});
}
