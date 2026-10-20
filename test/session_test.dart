import 'package:cedar_roots/core/providers.dart';
import 'package:cedar_roots/core/session.dart';
import 'package:cedar_roots/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts signed out when nothing is stored', () async {
    final container = await containerWith({});

    expect(container.read(sessionProvider), isNull);
    expect(container.read(currentUserIdProvider), isNull);
  });

  test('restores an existing login from the keys the old app used', () async {
    final container = await containerWith({
      'auth_token': 'abc',
      'user_id': 7,
      'name': 'Ada',
    });

    final session = container.read(sessionProvider);
    expect(session?.userId, 7);
    expect(session?.token, 'abc');
    expect(session?.name, 'Ada');
  });

  test('signIn stores the session and publishes the user id', () async {
    final container = await containerWith({});

    await container
        .read(sessionProvider.notifier)
        .signIn(
          token: 't',
          user: const User(id: 3, name: 'Bo', email: 'b@x.co'),
        );

    expect(container.read(currentUserIdProvider), 3);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('auth_token'), 't');
    expect(prefs.getInt('user_id'), 3);
  });

  test('signOut clears credentials and cached data', () async {
    final container = await containerWith({
      'auth_token': 'abc',
      'user_id': 7,
      'cache:posts': '[]',
    });

    await container.read(sessionProvider.notifier).signOut();

    expect(container.read(sessionProvider), isNull);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getInt('user_id'), isNull);
    expect(
      prefs.getString('cache:posts'),
      isNull,
      reason: 'next user must not see old data',
    );
  });
}
