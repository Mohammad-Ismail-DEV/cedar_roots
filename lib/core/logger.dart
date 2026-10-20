import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Debug-only logging; replaces scattered print() calls.
class AppLog {
  AppLog._();

  static void d(String message, [String tag = 'app']) {
    if (kDebugMode) developer.log(message, name: tag);
  }

  static void w(String message, [String tag = 'app']) {
    if (kDebugMode) developer.log(message, name: tag, level: 900);
  }

  static void e(String message, [Object? error, String tag = 'app']) {
    if (kDebugMode) {
      developer.log(message, name: tag, level: 1000, error: error);
    }
  }
}
