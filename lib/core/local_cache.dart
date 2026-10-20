import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small JSON cache so screens can show the last known data instantly while
/// fresh data loads. Cleared on sign-out.
class LocalCache {
  LocalCache(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'cache:';

  dynamic read(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String key, Object? json) =>
      _prefs.setString('$_prefix$key', jsonEncode(json));

  Future<void> clear() async {
    for (final key
        in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await _prefs.remove(key);
    }
  }
}
