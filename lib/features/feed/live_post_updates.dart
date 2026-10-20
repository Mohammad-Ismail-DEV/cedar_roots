import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../../core/providers.dart';
import '../../data/post_repository.dart';
import 'feed_provider.dart';
import 'post_details_provider.dart';

/// Keeps likes and comments live: the server announces `post_changed` with a post id and we
/// re-fetch just that post, but only if it is on screen (open details page or in the feed).
/// Watch once near the app root.
final livePostUpdatesProvider = Provider<void>((ref) {
  final socket = ref.watch(socketClientProvider);

  final subscription = socket.on('post_changed').listen((data) async {
    final id = data is Map ? (data['postId'] as num?)?.toInt() : null;
    if (id == null) return;

    try {
      if (ref.exists(postDetailsProvider(id))) {
        await ref.read(postDetailsProvider(id).notifier).reload();
        return;
      }
      final inFeed = ref
          .read(feedProvider)
          .valueOrNull
          ?.any((item) => item is PostFeedItem && item.post.id == id);
      if (inFeed != true) return;
      final post = await ref.read(postRepositoryProvider).getById(id);
      ref.read(feedProvider.notifier).replacePost(post);
    } catch (e) {
      AppLog.w('live update for post $id failed: $e', 'socket');
    }
  });
  ref.onDispose(subscription.cancel);
});
