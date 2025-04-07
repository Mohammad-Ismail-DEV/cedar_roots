import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io('https://heavily-primary-mallard.ngrok-free.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket');
      socket.emit('join', userId);
    });

    socket.on('receive_message', (data) {
      // Update your message UI
    });

    socket.on('receive_notification', (data) {
      // Handle notification
    });

    socket.on('receive_group_message', (data) {
      // Update group chat UI
    });

    socket.onDisconnect((_) => print('Socket disconnected'));
  }

  void sendMessage(String senderId, String receiverId, String content) {
    socket.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }

  void sendGroupMessage(String groupId, String senderId, String content) {
    socket.emit('send_group_message', {
      'groupId': groupId,
      'senderId': senderId,
      'content': content,
    });
  }

  void sendNotification(String receiverId, String message) {
    socket.emit('send_notification', {
      'receiverId': receiverId,
      'message': message,
    });
  }

  void joinGroup(String groupId) {
    socket.emit('join_group', groupId);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(
    String senderId,
    String receiverId,
    int page,
  ) async {
    // Use HTTP or socket event to get message list from server
    // This is just a placeholder
    socket.emit('fetch_messages', {
      'senderId': senderId,
      'receiverId': receiverId,
      'page': page,
    });

    List<Map<String, dynamic>> messages = [];

    // Handle this on the server side to emit 'fetched_messages' back
    socket.on('fetched_messages', (data) {
      messages = List<Map<String, dynamic>>.from(data);
    });

    return Future.delayed(Duration(milliseconds: 300), () => messages);
  }

  void fetchGroupMessages(String groupId, int page) {
    socket.emit('fetch_group_messages', {'groupId': groupId, 'page': page});
  }

  void disconnect() {
    socket.disconnect();
  }
}
