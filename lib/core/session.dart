import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'providers.dart';

class Session {
  const Session({required this.userId, required this.token, this.name});

  final int userId;
  final String token;
  final String? name;
}

/// The one source of truth for "who is signed in". Null means signed out.
final sessionProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

/// The signed-in user's id, or null when signed out.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(sessionProvider)?.userId,
);

class SessionController extends Notifier<Session?> {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _loggedInKey = 'is_logged_in';
  static const _nameKey = 'name';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Session? build() {
    final token = _prefs.getString(_tokenKey);
    final userId = _prefs.getInt(_userIdKey);
    if (token == null || userId == null) return null;
    return Session(
      userId: userId,
      token: token,
      name: _prefs.getString(_nameKey),
    );
  }

  Future<void> signIn({required String token, required User user}) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setInt(_userIdKey, user.id);
    await _prefs.setBool(_loggedInKey, true);
    await _prefs.setString(_nameKey, user.name);
    await _prefs.setString('username', user.name);
    if (user.email != null) await _prefs.setString('email', user.email!);
    state = Session(userId: user.id, token: token, name: user.name);
  }

  /// Keeps the saved name and email in step after the user edits their profile.
  Future<void> updateProfile({String? name, String? email}) async {
    final current = state;
    if (current == null) return;
    if (name != null) {
      await _prefs.setString(_nameKey, name);
      await _prefs.setString('username', name);
    }
    if (email != null) await _prefs.setString('email', email);
    if (name != null) {
      state = Session(userId: current.userId, token: current.token, name: name);
    }
  }

  Future<void> signOut() async {
    if (state == null) return;
    state = null;
    for (final key in [
      _tokenKey,
      _userIdKey,
      _loggedInKey,
      _nameKey,
      'username',
      'email',
    ]) {
      await _prefs.remove(key);
    }
    await ref.read(localCacheProvider).clear();
  }
}
