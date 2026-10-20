import 'package:cedar_roots/core/deep_links.dart';
import 'package:cedar_roots/core/providers.dart';
import 'package:cedar_roots/data/post_repository.dart';
import 'package:cedar_roots/data/story_repository.dart';
import 'package:cedar_roots/features/feed/saved_posts.dart';
import 'package:cedar_roots/features/feed/stories.dart';
import 'package:cedar_roots/models/message.dart';
import 'package:cedar_roots/models/preferences.dart';
import 'package:cedar_roots/models/presence.dart';
import 'package:cedar_roots/models/story.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> storyJson(int id, {bool viewed = false, int? views}) => {
  'id': id,
  'type': 'text',
  'text': 'hello',
  'bg': 2,
  'created_at': '2026-10-20T10:00:00.000Z',
  'expires_at': '2026-10-21T10:00:00.000Z',
  'viewed': viewed,
  if (views != null) 'view_count': views,
};

Map<String, dynamic> groupJson(
  int userId,
  List<Map<String, dynamic>> stories,
) => {
  'user': {'id': userId, 'name': 'User $userId'},
  'stories': stories,
};

class _FakePosts extends Fake implements PostRepository {
  _FakePosts({this.saved = const [], this.failToggle = false});

  List<int> saved;
  bool failToggle;
  final toggled = <int>[];

  @override
  Future<List<int>> savedIds() async => saved;

  @override
  Future<bool> toggleSave(int postId) async {
    if (failToggle) throw Exception('offline');
    toggled.add(postId);
    return !saved.contains(postId);
  }
}

class _FakeStories extends Fake implements StoryRepository {
  _FakeStories(this.groups);

  List<StoryGroup> groups;
  final viewed = <int>[];

  @override
  Future<List<StoryGroup>> feed() async => groups;

  @override
  Future<void> markViewed(int storyId) async => viewed.add(storyId);
}

Future<ProviderContainer> container(List<Override> overrides) async {
  SharedPreferences.setMockInitialValues({'auth_token': 'token', 'user_id': 1});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('story models', () {
    test('a group knows whether everything was seen and where to resume', () {
      final group = StoryGroup.fromJson(
        groupJson(2, [storyJson(1, viewed: true), storyJson(2), storyJson(3)]),
      );
      expect(group.allSeen, isFalse);
      expect(group.firstUnseenIndex, 1);

      final done = group.markViewed(2).markViewed(3);
      expect(done.allSeen, isTrue);
      expect(
        done.firstUnseenIndex,
        0,
        reason: 'replays from the start when all seen',
      );
    });

    test('view counts only come with my own stories', () {
      final mine = Story.fromJson(storyJson(1, viewed: true, views: 4));
      final theirs = Story.fromJson(storyJson(2));
      expect(mine.viewCount, 4);
      expect(theirs.viewCount, isNull);
      expect(mine.isImage, isFalse);
    });
  });

  group('presence', () {
    final now = DateTime(2026, 10, 20, 12);

    test('reads online or last seen', () {
      expect(const Presence(online: true).label(now: now), 'Active now');
      expect(
        Presence(
          online: false,
          lastSeenAt: now.subtract(const Duration(minutes: 5)),
        ).label(now: now),
        'Active 5m ago',
      );
      expect(
        Presence(
          online: false,
          lastSeenAt: now.subtract(const Duration(hours: 3)),
        ).label(now: now),
        'Active 3h ago',
      );
      expect(
        Presence(
          online: false,
          lastSeenAt: now.subtract(const Duration(days: 2)),
        ).label(now: now),
        'Active 2d ago',
      );
      expect(Presence.unknown.label(now: now), '');
    });
  });

  group('deep links', () {
    test('builds and parses post links', () {
      expect(postLink(42), 'cedarroots://post/42');
      final link = parseDeepLink(Uri.parse(postLink(42)));
      expect(link?.kind, DeepLinkKind.post);
      expect(link?.id, 42);
    });

    test('understands events, profiles and organizations', () {
      expect(
        parseDeepLink(Uri.parse('cedarroots://event/3'))?.kind,
        DeepLinkKind.event,
      );
      expect(
        parseDeepLink(Uri.parse('cedarroots://profile/4'))?.kind,
        DeepLinkKind.profile,
      );
      expect(
        parseDeepLink(Uri.parse('cedarroots://organization/5'))?.kind,
        DeepLinkKind.organization,
      );
    });

    test(
      'the shared web link opens the post and carries a preview-friendly text',
      () {
        final link = parseDeepLink(Uri.parse('https://example.test/p/7'));
        expect(link?.kind, DeepLinkKind.post);
        expect(link?.id, 7);
        expect(parseDeepLink(Uri.parse('https://example.test/p/x')), isNull);

        final text = postShareText(
          author: 'Layla',
          content: 'Plant trees',
          postId: 7,
        );
        expect(text, startsWith('Layla on Cedar Roots'));
        expect(text, contains('"Plant trees"'));
        expect(text, endsWith('/p/7'));
      },
    );

    test('ignores everything else', () {
      expect(parseDeepLink(Uri.parse('https://example.com/post/1')), isNull);
      expect(parseDeepLink(Uri.parse('cedarroots://post/abc')), isNull);
      expect(parseDeepLink(Uri.parse('cedarroots://post/0')), isNull);
      expect(parseDeepLink(Uri.parse('cedarroots://post')), isNull);
      expect(parseDeepLink(Uri.parse('cedarroots://unknown/1')), isNull);
    });
  });

  group('messages and preferences', () {
    test('a shared post is a message whose content is the post id', () {
      final message = Message(
        id: 1,
        senderId: 1,
        receiverId: 2,
        content: '77',
        sentAt: DateTime(2026),
        type: 'post',
      );
      expect(message.isPost, isTrue);
      expect(message.sharedPostId, 77);
      expect(message.isImage, isFalse);

      final text = Message(
        id: 2,
        senderId: 1,
        receiverId: 2,
        content: '77',
        sentAt: DateTime(2026),
      );
      expect(text.sharedPostId, isNull);
    });

    test('preferences default to on and read the server shape', () {
      expect(NotificationPreferences.fromJson(const {}).pushEnabled, isTrue);
      final off = NotificationPreferences.fromJson(const {
        'push_enabled': false,
        'event_reminders': false,
      });
      expect(off.pushEnabled, isFalse);
      expect(off.eventReminders, isFalse);
      expect(off.copyWith(pushEnabled: true).eventReminders, isFalse);
    });
  });

  group('saved posts', () {
    test(
      'loads the server bookmarks, then toggles and keeps them in sync',
      () async {
        final posts = _FakePosts(saved: [5]);
        final c = await container([
          postRepositoryProvider.overrideWithValue(posts),
        ]);

        c.listen(savedPostsProvider, (_, __) {});
        await Future<void>.delayed(Duration.zero);
        expect(c.read(savedPostsProvider), {5});

        final notifier = c.read(savedPostsProvider.notifier);
        await notifier.toggle(9);
        expect(c.read(savedPostsProvider), {5, 9});
        expect(posts.toggled, [9]);

        posts.saved = [5, 9];
        await notifier.toggle(9);
        expect(c.read(savedPostsProvider), {5});
      },
    );

    test('puts the bookmark back when the server refuses', () async {
      final posts = _FakePosts(saved: [5], failToggle: true);
      final c = await container([
        postRepositoryProvider.overrideWithValue(posts),
      ]);

      c.listen(savedPostsProvider, (_, __) {});
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        c.read(savedPostsProvider.notifier).toggle(9),
        throwsException,
      );
      expect(c.read(savedPostsProvider), {5});
    });
  });

  group('stories provider', () {
    test('marks a story seen on screen and tells the server', () async {
      final groups = [
        StoryGroup.fromJson(groupJson(2, [storyJson(10), storyJson(11)])),
      ];
      final stories = _FakeStories(groups);
      final c = await container([
        storyRepositoryProvider.overrideWithValue(stories),
      ]);

      c.listen(storiesProvider, (_, __) {});
      await c.read(storiesProvider.future);
      expect(c.read(storiesProvider).value!.single.allSeen, isFalse);

      final notifier = c.read(storiesProvider.notifier);
      await notifier.markViewed(2, 10);
      expect(
        c.read(storiesProvider).value!.single.stories.first.viewed,
        isTrue,
      );
      expect(c.read(storiesProvider).value!.single.allSeen, isFalse);

      await notifier.markViewed(2, 11);
      expect(c.read(storiesProvider).value!.single.allSeen, isTrue);
      expect(stories.viewed, [10, 11]);
    });

    test('my own group is found by my user id', () async {
      final stories = _FakeStories([
        StoryGroup.fromJson(
          groupJson(1, [storyJson(1, viewed: true, views: 2)]),
        ),
        StoryGroup.fromJson(groupJson(2, [storyJson(2)])),
      ]);
      final c = await container([
        storyRepositoryProvider.overrideWithValue(stories),
      ]);

      c.listen(storiesProvider, (_, __) {});
      await c.read(storiesProvider.future);
      expect(c.read(myStoriesProvider)?.user.id, 1);
      expect(c.read(myStoriesProvider)?.stories.single.viewCount, 2);
    });
  });
}
