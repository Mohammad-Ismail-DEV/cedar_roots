import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/event_repository.dart';
import '../../data/post_repository.dart';
import '../../models/event.dart';
import '../../models/post.dart';

sealed class FeedItem {
  const FeedItem();
  DateTime? get createdAt;
}

class PostFeedItem extends FeedItem {
  const PostFeedItem(this.post);
  final Post post;

  @override
  DateTime? get createdAt => post.createdAt;
}

class EventFeedItem extends FeedItem {
  const EventFeedItem(this.event);
  final Event event;

  @override
  DateTime? get createdAt => event.createdAt;
}

/// Posts and events merged into one newest-first feed. Not auto-disposed, so the
/// feed survives tab switches; it rebuilds itself when someone signs in or out.
final feedProvider = AsyncNotifierProvider<FeedNotifier, List<FeedItem>>(
  FeedNotifier.new,
);

class FeedNotifier extends AsyncNotifier<List<FeedItem>> {
  PostRepository get _posts => ref.read(postRepositoryProvider);
  EventRepository get _events => ref.read(eventRepositoryProvider);

  @override
  Future<List<FeedItem>> build() async {
    final userId = ref.watch(currentUserIdProvider);

    final cachedPosts = _posts.cachedFeed();
    final cachedEvents = _events.cachedEvents();
    if (cachedPosts != null || cachedEvents != null) {
      // Show what we had instantly, then update in the background.
      unawaited(refresh().catchError((_) {}));
      return _merge(cachedPosts ?? const [], cachedEvents ?? const []);
    }
    return _fetch(userId);
  }

  Future<List<FeedItem>> _fetch(int? userId) async {
    final results = await Future.wait([
      _posts.fetchFeed(userId: userId),
      _events.fetchEvents(userId: userId),
    ]);
    return _merge(results[0] as List<Post>, results[1] as List<Event>);
  }

  List<FeedItem> _merge(List<Post> posts, List<Event> events) {
    final items = <FeedItem>[
      ...posts.map(PostFeedItem.new),
      ...events.map(EventFeedItem.new),
    ];
    items.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return items;
  }

  bool _polling = false;

  /// Background check for new posts and events. Only replaces the feed (and so only rebuilds
  /// the list) when the server's copy differs from what is on screen, and never throws.
  Future<void> poll() async {
    final current = state.valueOrNull;
    if (_polling || current == null) return;
    _polling = true;
    try {
      final before = feedSignature(current);
      final fresh = await _fetch(ref.read(currentUserIdProvider));
      final now = state.valueOrNull;
      // Skip if the user liked, deleted or refreshed while we were fetching: our copy is stale.
      if (now == null || feedSignature(now) != before) return;
      if (feedSignature(fresh) != before) state = AsyncData(fresh);
    } catch (_) {
      // Next tick tries again.
    } finally {
      _polling = false;
    }
  }

  /// Throws on failure so pull-to-refresh can tell the user; the old feed stays.
  Future<void> refresh() async {
    final fresh = await _fetch(ref.read(currentUserIdProvider));
    state = AsyncData(fresh);
  }

  void replacePost(Post post) => _mapPosts((p) => p.id == post.id ? post : p);

  void _mapPosts(Post Function(Post) change) {
    final items = state.valueOrNull;
    if (items == null) return;
    state = AsyncData([
      for (final item in items)
        item is PostFeedItem ? PostFeedItem(change(item.post)) : item,
    ]);
  }

  /// Likes instantly and rolls back if the server refuses.
  Future<void> toggleLike(int postId) async {
    final me = ref.read(currentUserIdProvider);
    final before = state.valueOrNull;
    if (me == null || before == null) return;

    _mapPosts((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        likes:
            p.isLikedBy(me)
                ? p.likes.where((l) => l.userId != me).toList()
                : [...p.likes, Like(userId: me)],
      );
    });

    try {
      await _posts.toggleLike(postId);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> deletePost(int postId) async {
    await _posts.delete(postId);
    final items = state.valueOrNull;
    if (items == null) return;
    state = AsyncData([
      for (final item in items)
        if (!(item is PostFeedItem && item.post.id == postId)) item,
    ]);
  }
}

/// A cheap fingerprint of everything the feed shows, to tell whether a refetch changed anything.
String feedSignature(List<FeedItem> items) => items
    .map((item) {
      if (item is PostFeedItem) {
        final p = item.post;
        return 'p${p.id}|${p.content}|${p.imageUrl}|'
            '${p.likes.map((l) => l.userId).join(',')}|'
            '${p.comments.map((c) => '${c.id}:${c.content}').join(',')}';
      }
      final e = (item as EventFeedItem).event;
      return 'e${e.id}|${e.title}|${e.description}|${e.location}|${e.dateTime}|'
          '${e.organization?.name}';
    })
    .join('\n');
