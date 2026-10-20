// End-to-end check of stories, saved posts, preferences, presence, post sharing, profile editing
// and password changes against a REAL backend and database (the app's own repositories and
// providers, no UI).
//
// 1. Start the backend (port 3000 or PORT=3999 node src/server.js).
// 2. Create two users:   cd backend && node scripts/e2e-users.js create
// 3. Run (paste the JSON from step 2 as E2E_USERS):
//      flutter test test/e2e/features_e2e_test.dart \
//        --dart-define=API_URL=http://localhost:3000 \
//        --dart-define='E2E_USERS={"password":"...","users":[{"id":1,"email":"..."},{"id":2,"email":"..."}]}'
// 4. Clean up:           node scripts/e2e-users.js remove <id> <id>
//
// Without E2E_USERS the tests are skipped.
import 'dart:convert';

import 'package:cedar_roots/core/providers.dart';
import 'package:cedar_roots/data/auth_repository.dart';
import 'package:cedar_roots/data/chat_repository.dart';
import 'package:cedar_roots/data/connection_repository.dart';
import 'package:cedar_roots/data/post_repository.dart';
import 'package:cedar_roots/data/preference_repository.dart';
import 'package:cedar_roots/data/story_repository.dart';
import 'package:cedar_roots/data/user_repository.dart';
import 'package:cedar_roots/features/chat/presence_provider.dart';
import 'package:cedar_roots/features/feed/saved_posts.dart';
import 'package:cedar_roots/features/feed/stories.dart';
import 'package:cedar_roots/features/profile/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usersJson = String.fromEnvironment('E2E_USERS');

class _Client {
  _Client(this.container, this.userId, this.email);
  final ProviderContainer container;
  final int userId;
  final String email;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);
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
  container.listen(socketLifecycleProvider, (_, __) {});

  await container
      .read(authRepositoryProvider)
      .login(email: user['email'] as String, password: password);
  await container.read(socketClientProvider).whenConnected();
  return _Client(container, user['id'] as int, user['email'] as String);
}

void main() {
  final skip = _usersJson.isEmpty ? 'set E2E_USERS (see file header)' : null;

  group('new features against a real backend', skip: skip, () {
    late _Client a;
    late _Client b;
    late String password;
    late int postId;

    setUpAll(() async {
      final config = jsonDecode(_usersJson) as Map<String, dynamic>;
      final users = (config['users'] as List).cast<Map<String, dynamic>>();
      password = config['password'] as String;
      a = await _signIn(users[0], password);
      b = await _signIn(users[1], password);

      // Connect A and B.
      await a.read(connectionRepositoryProvider).request(b.userId);
      final connection = await b
          .read(connectionRepositoryProvider)
          .between(b.userId, a.userId);
      await b
          .read(connectionRepositoryProvider)
          .respond(connection!.id, accept: true);

      // One post by A for saving and sharing.
      await a.read(postRepositoryProvider).create(content: 'e2e post');
      final posts = await a
          .read(postRepositoryProvider)
          .fetchByAuthor(a.userId);
      postId = posts.first.id;
    });

    tearDownAll(() {
      a.container.dispose();
      b.container.dispose();
    });

    test('editing the profile stores and returns bio and location', () async {
      await a
          .read(userRepositoryProvider)
          .update(
            a.userId,
            name: 'E2E Renamed',
            bio: 'My bio',
            location: 'Bcharre',
          );

      final profile = await a.container.read(profileProvider(a.userId).future);
      expect(profile.user.name, 'E2E Renamed');
      expect(profile.user.bio, 'My bio');
      expect(profile.user.location, 'Bcharre');

      final seenByB = await b.read(userRepositoryProvider).getById(a.userId);
      expect(seenByB.bio, 'My bio');
      expect(seenByB.location, 'Bcharre');
    });

    test(
      'a story reaches a connection, is marked seen and lists its viewers',
      () async {
        final story = await a
            .read(storyRepositoryProvider)
            .createText('Hello from e2e', bg: 3);
        expect(story.text, 'Hello from e2e');
        expect(story.bg, 3);
        expect(
          story.expiresAt.difference(story.createdAt),
          const Duration(hours: 24),
        );

        b.container.listen(storiesProvider, (_, __) {});
        await waitFor(
          () =>
              b.container
                  .read(storiesProvider)
                  .valueOrNull
                  ?.any((g) => g.user.id == a.userId) ??
              false,
          reason: "A's story in B's feed",
        );
        final group = b.container
            .read(storiesProvider)
            .value!
            .firstWhere((g) => g.user.id == a.userId);
        expect(group.allSeen, isFalse);

        await b.container
            .read(storiesProvider.notifier)
            .markViewed(a.userId, story.id);
        expect(
          b.container
              .read(storiesProvider)
              .value!
              .firstWhere((g) => g.user.id == a.userId)
              .allSeen,
          isTrue,
        );

        final viewers = await a.read(storyRepositoryProvider).viewers(story.id);
        expect(viewers.map((v) => v.user.id), [b.userId]);

        final mine = await a.read(storyRepositoryProvider).feed();
        expect(mine.first.user.id, a.userId);
        expect(mine.first.stories.first.viewCount, 1);

        await a.read(storyRepositoryProvider).delete(story.id);
        final after = await b.read(storyRepositoryProvider).feed();
        expect(after.any((g) => g.user.id == a.userId), isFalse);
      },
    );

    test('saved posts live on the server and follow the account', () async {
      b.container.listen(savedPostsProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(b.container.read(savedPostsProvider), isEmpty);

      await b.container.read(savedPostsProvider.notifier).toggle(postId);
      expect(b.container.read(savedPostsProvider), {postId});

      // A second device (a fresh container for the same account) sees it too.
      final second = await _signIn({
        'id': b.userId,
        'email': b.email,
      }, password);
      addTearDown(second.container.dispose);
      second.container.listen(savedPostsProvider, (_, __) {});
      await waitFor(
        () => second.container.read(savedPostsProvider).contains(postId),
        reason: 'the bookmark on the second device',
      );
      final saved = await second.container.read(
        savedPostObjectsProvider.future,
      );
      expect(saved.map((p) => p.id), [postId]);

      await b.container.read(savedPostsProvider.notifier).toggle(postId);
      expect(b.container.read(savedPostsProvider), isEmpty);
    });

    test('notification preferences round-trip', () async {
      final repo = a.read(preferenceRepositoryProvider);
      expect((await repo.get()).pushEnabled, isTrue);

      final changed = await repo.update(eventReminders: false);
      expect(changed.eventReminders, isFalse);
      expect(changed.pushEnabled, isTrue);
      expect((await repo.get()).eventReminders, isFalse);

      await repo.update(eventReminders: true);
    });

    test('a connection shows as online while their socket is open', () async {
      b.container.listen(presenceProvider(a.userId), (_, __) {});
      await waitFor(
        () => b.container.read(presenceProvider(a.userId)).online,
        reason: 'A to show online to B',
      );
      expect(
        b.container.read(presenceProvider(a.userId)).label(),
        'Active now',
      );
    });

    test('sharing a post arrives as a post message', () async {
      final received = a.read(chatRepositoryProvider).incoming.first;
      await b
          .read(chatRepositoryProvider)
          .sendPost(receiverId: a.userId, postId: postId);

      final message = await received.timeout(const Duration(seconds: 5));
      expect(message.isPost, isTrue);
      expect(message.sharedPostId, postId);
      expect(message.senderId, b.userId);
    });

    test('sharing a post that does not exist fails cleanly', () async {
      await expectLater(
        b
            .read(chatRepositoryProvider)
            .sendPost(receiverId: a.userId, postId: 999999999),
        throwsA(predicate((e) => '$e'.contains('Post not found'))),
      );
    });

    test('changing the password needs the current one', () async {
      final auth = b.read(authRepositoryProvider);
      await expectLater(
        auth.changePassword(
          currentPassword: 'wrong-password',
          newPassword: 'Another-pass1',
        ),
        throwsA(predicate((e) => '$e'.contains('incorrect'))),
      );

      await auth.changePassword(
        currentPassword: password,
        newPassword: 'Another-pass1',
      );
      final fresh = await _signIn({
        'id': b.userId,
        'email': b.email,
      }, 'Another-pass1');
      addTearDown(fresh.container.dispose);

      // Put it back so the shared test users stay usable.
      await fresh
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: 'Another-pass1',
            newPassword: password,
          );
    });
  });
}
