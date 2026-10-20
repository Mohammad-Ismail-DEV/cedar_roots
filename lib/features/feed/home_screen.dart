import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../shared/widgets/wordmark.dart';
import '../chat/conversations_provider.dart';
import '../notifications/notifications_provider.dart';
import '../profile/profile_provider.dart';
import '../shell/app_routes.dart';
import 'feed_provider.dart';
import 'saved_posts.dart';
import 'stories.dart';
import 'story_viewer_screen.dart';
import 'widgets/comment_sheet.dart';
import 'widgets/post_card.dart';
import 'widgets/post_menu.dart';
import 'widgets/stories_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    try {
      await ref.read(feedProvider.notifier).refresh();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  bool _requireLogin(String action) {
    if (ref.read(currentUserIdProvider) != null) return true;
    showSnack(context, 'Login to $action');
    return false;
  }

  Future<void> _like(int postId) async {
    if (!_requireLogin('like')) return;
    try {
      await ref.read(feedProvider.notifier).toggleLike(postId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _comment(int postId) {
    if (!_requireLogin('comment')) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentSheet(postId: postId),
    );
  }

  Future<void> _edit(int postId) async {
    final items = ref.read(feedProvider).valueOrNull ?? const [];
    final post =
        items
            .whereType<PostFeedItem>()
            .firstWhere((i) => i.post.id == postId)
            .post;
    await Navigator.push(context, AppRoutes.createPost(editing: post));
  }

  Future<void> _delete(int postId) async {
    final confirmed = await confirm(
      context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(feedProvider.notifier).deletePost(postId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  void _save(int postId) {
    if (!_requireLogin('save posts')) return;
    ref.read(savedPostsProvider.notifier).toggle(postId);
  }

  void _openStory(List<StoryEntry> entries, int index) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder:
            (_, __, ___) =>
                StoryViewerScreen(entries: entries, initialIndex: index),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required String tooltip,
    required int count,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: context.palette.heart,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final loggedIn = me != null;
    final feed = ref.watch(feedProvider);
    final saved = ref.watch(savedPostsProvider);
    final stories = ref.watch(storiesProvider);
    final myUser =
        loggedIn ? ref.watch(profileProvider(me)).valueOrNull?.user : null;

    final unreadAlerts =
        ref
            .watch(notificationsProvider)
            .valueOrNull
            ?.where((n) => !n.isRead)
            .length ??
        0;
    final unreadChats =
        ref
            .watch(conversationsProvider)
            .valueOrNull
            ?.fold<int>(0, (sum, c) => sum + c.unreadCount) ??
        0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Wordmark(),
        actions: [
          if (loggedIn) ...[
            _headerIcon(
              icon: Icons.favorite_border,
              tooltip: 'Notifications',
              count: unreadAlerts,
              onPressed:
                  () => Navigator.push(context, AppRoutes.notifications()),
            ),
            _headerIcon(
              icon: Icons.send_outlined,
              tooltip: 'Messages',
              count: unreadChats,
              onPressed: () => Navigator.push(context, AppRoutes.chats()),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(feedProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (items) {
          final posts = items.whereType<PostFeedItem>().map((i) => i.post);
          final unseen = {
            for (final s in stories)
              if (!s.seen) s.author.id,
          };

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (loggedIn) ...[
                  StoriesRow(
                    me: myUser,
                    entries: stories,
                    onYourStory:
                        () => Navigator.push(context, AppRoutes.createPost()),
                    onOpen: (i) => _openStory(stories, i),
                  ),
                  const Divider(),
                ],
                if (posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: Center(child: Text('Nothing here yet.')),
                  ),
                for (final post in posts)
                  PostCard(
                    key: ValueKey(post.id),
                    post: post,
                    currentUserId: me ?? 0,
                    saved: saved.contains(post.id),
                    hasStory: unseen.contains(post.userId),
                    onOpen:
                        () => Navigator.push(context, AppRoutes.post(post.id)),
                    onOpenAuthor:
                        () => Navigator.push(
                          context,
                          AppRoutes.profile(post.userId),
                        ),
                    onViewPhoto:
                        () => Navigator.push(context, AppRoutes.post(post.id)),
                    onLike: () => _like(post.id),
                    onComment: () => _comment(post.id),
                    onSave: () => _save(post.id),
                    onMenu:
                        () => showPostMenu(
                          context,
                          isMine: post.userId == me,
                          onOpen:
                              () => Navigator.push(
                                context,
                                AppRoutes.post(post.id),
                              ),
                          onEdit: () => _edit(post.id),
                          onDelete: () => _delete(post.id),
                        ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
