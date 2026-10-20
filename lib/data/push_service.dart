import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../core/providers.dart';
import '../core/socket_client.dart';

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(ref.watch(socketClientProvider)),
);

/// Registers this device's FCM token with the backend (over the socket).
class PushService {
  PushService(this._socket);

  final SocketClient _socket;

  static final _deviceInfo = DeviceInfoPlugin();

  /// The backend only accepts android and ios tokens.
  static String? get platform {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  Future<String> _deviceId() async {
    if (Platform.isAndroid) return (await _deviceInfo.androidInfo).id;
    final ios = await _deviceInfo.iosInfo;
    return ios.identifierForVendor ?? 'unknown_ios_device';
  }

  Future<void> register(String fcmToken) async {
    final platform = PushService.platform;
    if (platform == null) return;
    try {
      await _socket.whenConnected();
      await _socket.request(
        'store_fcm_token',
        {
          'fcm_token': fcmToken,
          'device_id': await _deviceId(),
          'platform': platform,
        },
        responseEvent: 'fcm_stored',
        errorEvent: 'fcm_error',
      );
    } on SocketRequestException catch (e) {
      AppLog.w('could not register push token: $e', 'push');
    }
  }

  /// Best effort: sign-out must never be blocked by this.
  Future<void> unregister() async {
    if (PushService.platform == null || !_socket.isConnected) return;
    try {
      await _socket.request(
        'remove_fcm_device_token',
        {'deviceId': await _deviceId()},
        responseEvent: 'fcm_token_removed',
        timeout: const Duration(seconds: 3),
      );
    } on SocketRequestException catch (e) {
      AppLog.w('could not unregister push token: $e', 'push');
    }
  }
}
