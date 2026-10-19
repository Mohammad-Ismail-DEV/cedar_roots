import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Server addresses. Override at build time:
///   flutter run --dart-define=API_URL=http://192.168.1.20:3000
class AppConfig {
  AppConfig._();

  static const _apiUrlOverride = String.fromEnvironment('API_URL');
  static const _socketUrlOverride = String.fromEnvironment('SOCKET_URL');

  /// The Android emulator reaches the host machine at 10.0.2.2, not localhost.
  static String get apiUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get socketUrl =>
      _socketUrlOverride.isNotEmpty ? _socketUrlOverride : apiUrl;
}
