import 'package:cedar_roots/core/providers.dart';
import 'package:cedar_roots/data/story_repository.dart';
import 'package:cedar_roots/features/feed/story_viewer_screen.dart';
import 'package:cedar_roots/models/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStories extends Fake implements StoryRepository {
  _FakeStories(this.groups);
  final List<StoryGroup> groups;
  final viewed = <int>[];

  @override
  Future<List<StoryGroup>> feed() async => groups;

  @override
  Future<void> markViewed(int storyId) async => viewed.add(storyId);
}

Map<String, dynamic> story(int id, {String type = 'text'}) => {
  'id': id,
  'type': type,
  'text': 'Story $id',
  'bg': 1,
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'expires_at':
      DateTime.now().add(const Duration(hours: 23)).toUtc().toIso8601String(),
  'viewed': false,
};

StoryGroup group(int userId, List<Map<String, dynamic>> stories) =>
    StoryGroup.fromJson({
      'user': {'id': userId, 'name': 'User $userId'},
      'stories': stories,
    });

Future<dynamic> pumpViewer(
  WidgetTester tester,
  List<StoryGroup> groups, {
  int initial = 0,
  int me = 1,
}) async {
  SharedPreferences.setMockInitialValues({'auth_token': 't', 'user_id': me});
  final prefs = await SharedPreferences.getInstance();
  final repo = _FakeStories(groups);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storyRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: StoryViewerScreen(groups: groups, initialGroup: initial),
      ),
    ),
  );
  await tester.pump();
  return repo;
}

void main() {
  testWidgets('opens on someone else\'s story and marks it viewed', (
    tester,
  ) async {
    final repo = await pumpViewer(tester, [
      group(2, [story(10), story(11)]),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Story 10'), findsOneWidget);
    expect(find.text('Send message'), findsOneWidget);
    expect(find.textContaining('User 2', findRichText: true), findsOneWidget);
    expect(repo.viewed, [10]);
  });

  testWidgets('tapping the right side goes to the next story, left goes back', (
    tester,
  ) async {
    final repo = await pumpViewer(tester, [
      group(2, [story(10), story(11)]),
    ]);

    await tester.tapAt(const Offset(700, 300));
    await tester.pump();
    expect(find.text('Story 11'), findsOneWidget);
    expect(repo.viewed, [10, 11]);

    await tester.tapAt(const Offset(20, 300));
    await tester.pump();
    expect(find.text('Story 10'), findsOneWidget);
  });

  testWidgets('moves on to the next person after the last story', (
    tester,
  ) async {
    await pumpViewer(tester, [
      group(2, [story(10)]),
      group(3, [story(20)]),
    ]);

    await tester.tapAt(const Offset(700, 300));
    await tester.pump();
    expect(find.text('Story 20'), findsOneWidget);
    expect(find.textContaining('User 3', findRichText: true), findsOneWidget);
  });

  testWidgets('my own story shows the viewer count and delete', (tester) async {
    final mine = StoryGroup.fromJson({
      'user': {'id': 1, 'name': 'Me'},
      'stories': [
        {...story(5), 'viewed': true, 'view_count': 3},
      ],
    });
    await pumpViewer(tester, [mine]);

    expect(
      find.textContaining('Your story', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('3 viewers'), findsOneWidget);
    expect(find.byTooltip('Delete story'), findsOneWidget);
    expect(find.text('Send message'), findsNothing);
  });

  testWidgets('advances by itself after five seconds', (tester) async {
    await pumpViewer(tester, [
      group(2, [story(10), story(11)]),
    ]);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text('Story 11'), findsOneWidget);
  });
}
