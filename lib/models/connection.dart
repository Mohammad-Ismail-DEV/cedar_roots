import 'json_helpers.dart';
import 'user.dart';

/// Relationship between the signed-in user and another user.
enum ConnectionStatus {
  none,
  accepted,
  pendingSent,
  pendingReceived;

  static ConnectionStatus parse(Object? value) => switch (value) {
    'accepted' => accepted,
    'pending_sent' => pendingSent,
    'pending_received' => pendingReceived,
    _ => none,
  };
}

class Connection {
  const Connection({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.sender,
    this.receiver,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final User? sender;
  final User? receiver;

  /// The user on the other side of this connection.
  User? other(int myId) => senderId == myId ? receiver : sender;

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    id: asInt(json['id']),
    senderId: asInt(json['sender_id']),
    receiverId: asInt(json['receiver_id']),
    status: (json['status'] ?? '').toString(),
    sender: User.maybe(json['Sender']),
    receiver: User.maybe(json['Receiver']),
  );
}

class UserConnections {
  const UserConnections({
    this.accepted = const [],
    this.requests = const [],
    this.outgoing = const [],
  });

  final List<Connection> accepted;
  final List<Connection> requests;
  final List<Connection> outgoing;

  factory UserConnections.fromJson(Map<String, dynamic> json) =>
      UserConnections(
        accepted: asMapList(json['accepted']).map(Connection.fromJson).toList(),
        requests: asMapList(json['requests']).map(Connection.fromJson).toList(),
        outgoing: asMapList(json['outgoing']).map(Connection.fromJson).toList(),
      );
}
