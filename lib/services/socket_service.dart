import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';

final String platform =
    kIsWeb
        ? 'web'
        : Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
        ? 'macos'
        : Platform.isLinux
        ? 'linux'
        : Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : 'unknown';

class SocketService {
  late IO.Socket socket;
  late SharedPreferences prefs;
  int? _userId; // Made nullable to prevent LateInitializationError
  List<Map<String, dynamic>> allMessages = [];
  List<Map<String, dynamic>> messages = [];

  SocketService() {
    socket = IO.io('http://13.50.2.82:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
  }

  /// Must be called before using prefs or socket
  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<String> getDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (kIsWeb) {
      return 'web_device';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfoPlugin.macOsInfo;
      return macInfo.systemGUID ?? 'mac_device';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfoPlugin.windowsInfo;
      return windowsInfo.deviceId;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfoPlugin.linuxInfo;
      return linuxInfo.machineId ?? 'linux_device';
    } else {
      return 'unknown_device';
    }
  }

  Function(Map<String, dynamic> message)? onMessageReceived;

  void connect(int userId) {
    _userId = userId;
    socket.connect();

    socket.onConnect((_) {
      socket.emit('join', _userId);
      print('✅ Connected and joined as user $_userId');
    });

    socket.onDisconnect((_) => print('🔌 Socket disconnected'));

    socket.on('receive_message', (data) {
      print('📥 Message received: $data');
      if (onMessageReceived != null) onMessageReceived!(data);
    });

    socket.on('fcm_token_removed', (data) {
      if (data['success'] == true) {
        print("✅ FCM token removed successfully.");
      } else {
        print("❌ Failed to remove FCM token: ${data['error']}");
      }
    });
  }

  void storeFcmToken(String token) async {
    await initialize();
    _userId = prefs.getInt("user_id");
    if (prefs.getBool("isLoggedIn") == true) {
      if (_userId == null) {
        print('⚠️ Cannot store FCM token: userId is not set');
        return;
      }
    }

    final deviceId = await getDeviceId();

    socket.emit('store_fcm_token', {
      'user_id': _userId,
      'fcm_token': token,
      'device_id': deviceId,
      'platform': platform,
    });

    print('✅ FCM token stored for $_userId');
  }

  void sendMessage(int senderId, int receiverId, String content) {
    socket.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }

  void sendGroupMessage(int groupId, int senderId, String content) {
    socket.emit('send_group_message', {
      'groupId': groupId,
      'senderId': senderId,
      'content': content,
    });
  }

  void sendNotification(int receiverId, String message) {
    socket.emit('send_notification', {
      'receiverId': receiverId,
      'message': message,
    });
  }

  void joinGroup(int groupId) {
    socket.emit('join_group', groupId);
  }

  void fetchUserMessages() {
    if (_userId == null) {
      print('⚠️ Cannot fetch messages: userId is not set');
      return;
    }
    socket.emit('fetch_user_messages', {'userId': _userId});
  }

  Future removeFCMToken() async {
    await initialize();
    _userId = prefs.getInt("user_id");
    final deviceId = await getDeviceId();
    socket.emit("remove_fcm_device_token", {
      'userId': _userId,
      'deviceId': deviceId,
    });
    return true;
  }

  void disconnect() async {
    if (socket.connected) {
      socket.emit('disconnect');
      // socket.disconnect();
      print('🔌 Socket manually disconnected');
    } else {
      print('⚠️ Socket is not connected');
    }
  }
}
