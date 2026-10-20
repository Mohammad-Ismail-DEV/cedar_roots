import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/post_repository.dart';
import '../../models/post.dart';

/// Ids of the posts the signed-in user bookmarked. Stored on the server, so the same
/// bookmarks show up on every device.
final savedPostsProvider = NotifierProvider<SavedPostsNotifier, Set<int>>(
  SavedPostsNotifier.new,
);

class SavedPostsNotifier extends Notifier<Set<int>> {
  PostRepository get _repo => ref.read(postRepositoryProvider);

  @override
  Set<int> build() {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const {};
    Future.microtask(_load);
    return const {};
  }

  Future<void> _load() async {
    try {
      final ids = await _repo.savedIds();
      state = ids.toSet();
    } catch (_) {
      // Stays empty until the next sign-in or toggle; bookmarks are not critical to show.
    }
  }

  Future<void> refresh() => _load();

  /// Saves or un-saves right away and rolls back if the server refuses.
  Future<void> toggle(int postId) async {
    final before = state;
    final next = {...state};
    if (!next.remove(postId)) next.add(postId);
    state = next;

    try {
      final saved = await _repo.toggleSave(postId);
      // The server is the source of truth if it disagrees with the optimistic guess.
      if (saved != state.contains(postId)) {
        state = saved ? {...state, postId} : ({...state}..remove(postId));
      }
      ref.invalidate(savedPostObjectsProvider);
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}

/// The bookmarked posts themselves, newest bookmark first.
final savedPostObjectsProvider = FutureProvider.autoDispose<List<Post>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.read(postRepositoryProvider).savedPosts();
});
