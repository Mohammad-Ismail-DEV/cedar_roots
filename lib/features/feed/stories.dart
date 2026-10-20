import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/session.dart';
import '../../data/story_repository.dart';
import '../../models/story.dart';

/// Stories from me and my connections (the last 24 hours). Mine come first, then people
/// with something I have not watched. Refreshes itself when the server says stories changed.
final storiesProvider =
    AsyncNotifierProvider<StoriesNotifier, List<StoryGroup>>(
      StoriesNotifier.new,
    );

class StoriesNotifier extends AsyncNotifier<List<StoryGroup>> {
  StoryRepository get _repo => ref.read(storyRepositoryProvider);

  @override
  Future<List<StoryGroup>> build() async {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const [];

    final socket = ref.read(socketClientProvider);
    final live = socket
        .on('stories_changed')
        .listen((_) => unawaited(refresh().catchError((_) {})));
    final reconnected = socket.connection
        .where((connected) => connected)
        .listen((_) => unawaited(refresh().catchError((_) {})));
    ref.onDispose(() {
      live.cancel();
      reconnected.cancel();
    });

    return _repo.feed();
  }

  /// Throws on failure so pull-to-refresh can tell the user; the old rings stay.
  Future<void> refresh() async {
    state = AsyncData(await _repo.feed());
  }

  /// Marks a story watched on screen straight away and tells the server.
  Future<void> markViewed(int userId, int storyId) async {
    final groups = state.valueOrNull;
    if (groups == null) return;

    final me = ref.read(currentUserIdProvider);
    if (userId != me) {
      state = AsyncData([
        for (final g in groups)
          if (g.user.id == userId) g.markViewed(storyId) else g,
      ]);
    }
    try {
      await _repo.markViewed(storyId);
    } catch (_) {
      // Watching still works; the ring just stays unseen until the next refresh.
    }
  }

  Future<void> delete(int storyId) async {
    await _repo.delete(storyId);
    await refresh();
  }
}

/// My own group of stories, or null when I have none right now.
final myStoriesProvider = Provider<StoryGroup?>((ref) {
  final me = ref.watch(currentUserIdProvider);
  final groups = ref.watch(storiesProvider).valueOrNull ?? const [];
  for (final g in groups) {
    if (g.user.id == me) return g;
  }
  return null;
});
