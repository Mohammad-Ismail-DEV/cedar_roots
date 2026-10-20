import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/session.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import 'feed_provider.dart';

/// One person with something recent to show: their newest post.
class StoryEntry {
  const StoryEntry({
    required this.author,
    required this.latest,
    required this.seen,
  });

  final User author;
  final Post latest;
  final bool seen;
}

/// Post ids whose "story" the signed-in user already watched. Kept on the device.
final seenStoriesProvider = NotifierProvider<SeenStoriesNotifier, Set<int>>(
  SeenStoriesNotifier.new,
);

class SeenStoriesNotifier extends Notifier<Set<int>> {
  String? get _key {
    final me = ref.read(currentUserIdProvider);
    return me == null ? null : 'stories_seen:$me';
  }

  @override
  Set<int> build() {
    ref.watch(currentUserIdProvider);
    final key = _key;
    if (key == null) return const {};
    final seen = ref.read(sharedPreferencesProvider).getStringList(key);
    return {
      for (final id in seen ?? const <String>[])
        if (int.tryParse(id) case final n?) n,
    };
  }

  void mark(int postId) {
    if (state.contains(postId)) return;
    // Only the newest 200 are kept so the list cannot grow forever.
    final next = {...state, postId};
    final trimmed =
        next.length > 200 ? next.skip(next.length - 200).toSet() : next;
    state = trimmed;
    final key = _key;
    if (key != null) {
      ref.read(sharedPreferencesProvider).setStringList(key, [
        for (final id in trimmed) '$id',
      ]);
    }
  }
}

/// People (other than me) who posted in the last week, unseen first.
final storiesProvider = Provider<List<StoryEntry>>((ref) {
  final me = ref.watch(currentUserIdProvider);
  if (me == null) return const [];
  final seen = ref.watch(seenStoriesProvider);
  final items = ref.watch(feedProvider).valueOrNull ?? const [];

  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final newest = <int, Post>{};
  for (final item in items.whereType<PostFeedItem>()) {
    final post = item.post;
    if (post.userId == me || post.author == null) continue;
    final at = post.createdAt;
    if (at == null || at.isBefore(cutoff)) continue;
    final existing = newest[post.userId];
    if (existing == null || (existing.createdAt?.isBefore(at) ?? true)) {
      newest[post.userId] = post;
    }
  }

  final entries = [
    for (final post in newest.values)
      StoryEntry(
        author: post.author!,
        latest: post,
        seen: seen.contains(post.id),
      ),
  ]..sort((a, b) {
    if (a.seen != b.seen) return a.seen ? 1 : -1;
    return (b.latest.createdAt ?? DateTime(0)).compareTo(
      a.latest.createdAt ?? DateTime(0),
    );
  });

  return entries.take(15).toList();
});
