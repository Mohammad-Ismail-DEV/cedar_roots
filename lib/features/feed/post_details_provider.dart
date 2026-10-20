import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/post_repository.dart';
import '../../models/post.dart';
import 'feed_provider.dart';

/// One post with its comments and likes; shared by the details page and the
/// comments sheet. Every change is also pushed into the feed so counts match.
final postDetailsProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailsNotifier, Post, int>(PostDetailsNotifier.new);

class PostDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<Post, int> {
  PostRepository get _repo => ref.read(postRepositoryProvider);

  @override
  Future<Post> build(int arg) => _repo.getById(arg);

  Future<void> reload() async {
    final post = await _repo.getById(arg);
    _publish(post);
  }

  void _publish(Post post) {
    state = AsyncData(post);
    ref.read(feedProvider.notifier).replacePost(post);
  }

  Future<void> toggleLike() async {
    final me = ref.read(currentUserIdProvider);
    final before = state.valueOrNull;
    if (me == null || before == null) return;

    _publish(
      before.copyWith(
        likes:
            before.isLikedBy(me)
                ? before.likes.where((l) => l.userId != me).toList()
                : [...before.likes, Like(userId: me)],
      ),
    );
    try {
      await _repo.toggleLike(arg);
    } catch (_) {
      _publish(before);
      rethrow;
    }
  }

  Future<void> addComment(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    await _repo.addComment(arg, text);
    await reload();
  }

  Future<void> deleteComment(int commentId) async {
    await _repo.deleteComment(commentId);
    await reload();
  }
}
