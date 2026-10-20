import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/session.dart';
import '../../data/post_repository.dart';
import '../../models/post.dart';

/// Ids of the posts the signed-in user bookmarked. Kept on the device, per account.
final savedPostsProvider = NotifierProvider<SavedPostsNotifier, Set<int>>(
  SavedPostsNotifier.new,
);

class SavedPostsNotifier extends Notifier<Set<int>> {
  String? get _key {
    final me = ref.read(currentUserIdProvider);
    return me == null ? null : 'saved_posts:$me';
  }

  @override
  Set<int> build() {
    ref.watch(currentUserIdProvider);
    final key = _key;
    if (key == null) return const {};
    final saved = ref.read(sharedPreferencesProvider).getStringList(key);
    return {
      for (final id in saved ?? const <String>[])
        if (int.tryParse(id) case final n?) n,
    };
  }

  void toggle(int postId) {
    final next = {...state};
    if (!next.remove(postId)) next.add(postId);
    state = next;
    final key = _key;
    if (key != null) {
      ref.read(sharedPreferencesProvider).setStringList(key, [
        for (final id in next) '$id',
      ]);
    }
  }
}

/// The bookmarked posts themselves, newest bookmark id first. Posts deleted since are skipped.
final savedPostObjectsProvider = FutureProvider.autoDispose<List<Post>>((
  ref,
) async {
  final ids = ref.watch(savedPostsProvider).toList()..sort((a, b) => b - a);
  final repo = ref.read(postRepositoryProvider);
  final posts = await Future.wait(
    ids.map(
      (id) => repo.getById(id).then<Post?>((p) => p).catchError((_) => null),
    ),
  );
  return posts.whereType<Post>().toList();
});
