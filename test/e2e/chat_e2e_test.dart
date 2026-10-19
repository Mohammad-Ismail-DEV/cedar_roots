// End-to-end check of the chat state machine against a REAL backend and database.
//
// 1. Start the backend:        cd backend && PORT=3999 node src/server.js
// 2. Create two users:          node scripts/e2e-users.js create
// 3. Run (paste the JSON from step 2 as E2E_USERS):
//      flutter test test/e2e/chat_e2e_test.dart \
//        --dart-define=API_URL=http://localhost:3999 \
//        --dart-define='E2E_USERS={"password":"...","users":[{"id":1,"email":"..."},{"id":2,"email":"..."}]}'
// 4. Clean up:                  node scripts/e2e-users.js remove <id> <id>
//
// Without E2E_USERS the tests are skipped.
import 'dart:convert';

import 'package:cedar_roots/core/providers.dart';
import 'package:cedar_roots/data/auth_repository.dart';
import 'package:cedar_roots/features/chat/chat_controller.dart';
import 'package:cedar_roots/features/chat/conversations_provider.dart';
import 'package:cedar_roots/features/chat/delivery_receipts.dart';
import 'package:cedar_roots/models/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usersJson = String.fromEnvironment('E2E_USERS');

class _Client {
  _Client(this.container, this.userId);
  final ProviderContainer container;
  final int userId;

  ChatController chat(int otherId) =>
      container.read(chatControllerProvider(otherId).notifier);
  ChatState chatState(int otherId) =>
      container.read(chatControllerProvider(otherId));
}

Future<void> waitFor(
  bool Function() condition, {
  String reason = 'condition',
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for $reason');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<_Client> _signIn(Map<String, dynamic> user, String password) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Same always-on providers the real app watches at its root.
  container.listen(socketLifecycleProvider, (_, __) {});
  container.listen(deliveryReceiptsProvider, (_, __) {});

  await container
      .read(authRepositoryProvider)
      .login(email: user['email'] as String, password: password);
  await container.read(socketClientProvider).whenConnected();
  return _Client(container, user['id'] as int);
}

void main() {
  final skip = _usersJson.isEmpty ? 'set E2E_USERS (see file header)' : null;

  group('chat against a real backend', skip: skip, () {
    late _Client a;
    late _Client b;

    setUpAll(() async {
      final config = jsonDecode(_usersJson) as Map<String, dynamic>;
      final users = (config['users'] as List).cast<Map<String, dynamic>>();
      a = await _signIn(users[0], config['password'] as String);
      b = await _signIn(users[1], config['password'] as String);

      // Both users have the conversation open.
      for (final (client, other) in [(a, b.userId), (b, a.userId)]) {
        client.container.listen(chatControllerProvider(other), (_, __) {});
        await waitFor(
          () => !client.chatState(other).loading,
          reason: 'initial history load',
        );
      }
    });

    tearDownAll(() {
      a.container.dispose();
      b.container.dispose();
    });

    test(
      'a message goes sending -> sent -> seen and reaches the other user',
      () async {
        final seenStatuses = <MessageStatus>[];
        final sub = a.container.listen(chatControllerProvider(b.userId), (
          _,
          next,
        ) {
          final last = next.messages.lastOrNull;
          if (last != null && last.content == 'hello e2e') {
            seenStatuses.add(last.status);
          }
        });

        a.chat(b.userId).sendText('hello e2e');

        await waitFor(
          () =>
              a.chatState(b.userId).messages.lastOrNull?.status ==
              MessageStatus.seen,
          reason: 'message to be seen by the other user',
        );
        sub.close();

        expect(seenStatuses.first, MessageStatus.sending);
        expect(seenStatuses, contains(MessageStatus.sent));
        expect(seenStatuses.last, MessageStatus.seen);

        final mine = a.chatState(b.userId).messages.last;
        expect(
          mine.id,
          lessThan(1 << 40),
          reason: 'local id replaced by the server id',
        );
        expect(b.chatState(a.userId).messages.last.content, 'hello e2e');
        expect(b.chatState(a.userId).messages.last.senderId, a.userId);
      },
    );

    test(
      'messages arriving while scrolled up are counted, then cleared when read',
      () async {
        b.chat(a.userId).setAtBottom(false);

        a.chat(b.userId).sendText('ping 1');
        a.chat(b.userId).sendText('ping 2');

        await waitFor(
          () => b.chatState(a.userId).newMessages == 2,
          reason: 'two unread messages on the receiver',
        );
        final bState = b.chatState(a.userId);
        expect(bState.firstUnreadId, isNotNull);

        // Delivered (receipt is app-wide) but not seen while B is scrolled up.
        await waitFor(
          () =>
              a.chatState(b.userId).messages.last.status ==
              MessageStatus.delivered,
          reason: 'delivery receipt',
        );
        expect(
          a.chatState(b.userId).messages.last.status,
          isNot(MessageStatus.seen),
        );

        b.chat(a.userId).setAtBottom(true);
        expect(b.chatState(a.userId).newMessages, 0);
        await waitFor(
          () =>
              a.chatState(b.userId).messages.last.status == MessageStatus.seen,
          reason: 'messages seen after scrolling to bottom',
        );
      },
    );

    test('typing indicator reaches the other user', () async {
      a.chat(b.userId).notifyTyping();
      await waitFor(
        () => b.chatState(a.userId).otherTyping,
        reason: 'typing flag',
      );
    });

    test(
      'conversation list shows the partner, last message and no unread',
      () async {
        // autoDispose provider: keep it alive while the test reads it.
        final keepAlive = a.container.listen(conversationsProvider, (_, __) {});
        final list = await a.container.read(conversationsProvider.future);
        await a.container.read(conversationsProvider.notifier).refresh();
        final fresh = a.container.read(conversationsProvider).requireValue;

        expect(list, isNotEmpty);
        expect(fresh.length, 1);
        expect(fresh.single.userId, b.userId);
        expect(fresh.single.lastMessage?.content, 'ping 2');
        expect(fresh.single.unreadCount, 0);
        keepAlive.close();
      },
    );

    test('history paginates oldest-first without duplicates', () async {
      for (var i = 1; i <= 24; i++) {
        a.chat(b.userId).sendText('bulk $i');
      }
      await waitFor(
        () => a
            .chatState(b.userId)
            .messages
            .every((m) => m.status != MessageStatus.sending),
        reason: 'all bulk messages saved',
        timeout: const Duration(seconds: 20),
      );

      // A fresh install: no cached history, so the controller must page from the server.
      await a.container.read(localCacheProvider).clear();
      a.container.invalidate(chatControllerProvider(b.userId));
      final reopened = a.container.listen(
        chatControllerProvider(b.userId),
        (_, __) {},
      );
      await waitFor(
        () => !reopened.read().loading && reopened.read().messages.length >= 20,
        reason: 'reopened chat to load',
      );
      expect(reopened.read().messages.length, 20, reason: 'first page only');
      expect(reopened.read().hasMore, isTrue);

      while (a.chatState(b.userId).hasMore) {
        await a.chat(b.userId).loadMore();
      }
      final all = a.chatState(b.userId).messages;

      expect(all.length, greaterThanOrEqualTo(27));
      expect(
        all.map((m) => m.id).toSet().length,
        all.length,
        reason: 'no duplicates',
      );
      expect(
        [...all]..sort((x, y) => x.id.compareTo(y.id)),
        all,
        reason: 'oldest first',
      );
      expect(all.first.content, 'hello e2e');
      expect(all.last.content, 'bulk 24');
      expect(
        all.where((m) => m.content.startsWith('bulk ')).map((m) => m.content),
        [for (var i = 1; i <= 24; i++) 'bulk $i'],
        reason: 'rapid sends keep their order',
      );
      reopened.close();
    });
  });
}
