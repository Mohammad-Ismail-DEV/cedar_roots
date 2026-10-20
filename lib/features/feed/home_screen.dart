import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../chat/chats_screen.dart';
import '../shell/app_routes.dart';
import 'feed_provider.dart';
import 'widgets/comment_sheet.dart';
import 'widgets/event_card.dart';
import 'widgets/post_card.dart';
import 'widgets/search_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  Future<void> _refresh() async {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() => _query = '');
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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    final loggedIn = me != null;
    final feed = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cedar Roots'),
        actions: [
          if (loggedIn)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatsScreen()),
                  ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _search,
                  enabled: loggedIn,
                  onChanged: loggedIn ? _onSearchChanged : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: loggedIn ? 'Search' : 'Login to search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: feed.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
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
                  data:
                      (items) => RefreshIndicator(
                        onRefresh: _refresh,
                        child:
                            items.isEmpty
                                ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(child: Text('Nothing here yet.')),
                                  ],
                                )
                                : ListView.builder(
                                  itemCount: items.length,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  itemBuilder: (context, index) {
                                    return switch (items[index]) {
                                      EventFeedItem(:final event) => EventCard(
                                        event: event,
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              AppRoutes.event(event.id),
                                            ),
                                      ),
                                      PostFeedItem(:final post) => PostCard(
                                        post: post,
                                        currentUserId: me ?? 0,
                                        onOpen:
                                            () => Navigator.push(
                                              context,
                                              AppRoutes.post(post.id),
                                            ),
                                        onLike: () => _like(post.id),
                                        onComment: () => _comment(post.id),
                                        onEdit: () => _edit(post.id),
                                        onDelete: () => _delete(post.id),
                                      ),
                                    };
                                  },
                                ),
                      ),
                ),
              ),
            ],
          ),
          if (loggedIn && _query.isNotEmpty) SearchOverlay(query: _query),
        ],
      ),
    );
  }
}
