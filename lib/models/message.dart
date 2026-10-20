import 'json_helpers.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed;

  static MessageStatus parse(Object? value) => switch (value) {
    'delivered' => delivered,
    'seen' => seen,
    _ => sent,
  };
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.type = 'text',
    this.status = MessageStatus.sent,
    this.localId,
  });

  /// Server id, or the temporary [localId] while the message is still sending.
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final String type;
  final MessageStatus status;

  /// Client-generated id used to match the server's "message_saved" reply.
  final int? localId;

  bool get isImage => type == 'image';

  /// An image that has not been uploaded yet: [content] is a path on this device.
  bool get isLocal => isImage && !content.startsWith('http');
  bool isMine(int myId) => senderId == myId;

  Message copyWith({int? id, MessageStatus? status, String? content}) =>
      Message(
        id: id ?? this.id,
        senderId: senderId,
        receiverId: receiverId,
        content: content ?? this.content,
        sentAt: sentAt,
        type: type,
        status: status ?? this.status,
        localId: localId,
      );

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: asInt(json['id']),
    senderId: asInt(json['sender_id']),
    receiverId: asInt(json['receiver_id']),
    content: (json['content'] ?? '').toString(),
    sentAt: asDate(json['sent_at']) ?? DateTime.now(),
    type: (json['type'] ?? 'text').toString(),
    status: MessageStatus.parse(json['read_status']),
  );

  /// Only confirmed messages are cached, so this mirrors the server shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'sent_at': sentAt.toUtc().toIso8601String(),
    'type': type,
    'read_status': status.name,
  };
}

class Conversation {
  const Conversation({
    required this.userId,
    required this.name,
    this.profilePic,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final int userId;
  final String name;
  final String? profilePic;
  final Message? lastMessage;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final last = asMap(json['last_message']);
    return Conversation(
      userId: asInt(json['user_id']),
      name: (json['name'] ?? '').toString(),
      profilePic: asStringOrNull(json['profile_pic']),
      lastMessage: last == null ? null : Message.fromJson(last),
      unreadCount: asInt(json['unread_count']),
    );
  }
}
