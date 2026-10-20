import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/time_label.dart';
import '../../core/ui.dart';
import '../../models/post.dart';
import '../../shared/widgets/counted_icon_button.dart';
import '../../shared/widgets/post_media.dart';
import '../../shared/widgets/user_avatar.dart';
import '../chat/image_preview_screen.dart';
import '../feed/feed_provider.dart';
import '../feed/likes_line.dart';
import '../feed/saved_posts.dart';
import '../feed/widgets/post_menu.dart';
import '../feed/widgets/share_sheet.dart';
import '../profile/profile_provider.dart';
import '../shell/app_routes.dart';
import '../feed/post_details_provider.dart';
import '../feed/widgets/comment_tile.dart';
import 'create_post_screen.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final _comment = TextEditingController();

  PostDetailsNotifier get _notifier =>
      ref.read(postDetailsProvider(widget.postId).notifier);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool _requireLogin(String action) {
    if (ref.read(currentUserIdProvider) != null) return true;
    showSnack(context, 'Login to $action');
    return false;
  }

  Future<void> _toggleLike() async {
    if (!_requireLogin('like')) return;
    try {
      await _notifier.toggleLike();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _toggleSave(int postId) async {
    if (!_requireLogin('save posts')) return;
    try {
      await ref.read(savedPostsProvider.notifier).toggle(postId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _addComment() async {
    if (!_requireLogin('comment')) return;
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    try {
      await _notifier.addComment(text);
      _comment.clear();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _editPost(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CreatePostScreen(existingPost: post),
      ),
    );
    if (!mounted) return;
    try {
      await _notifier.reload();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await confirm(
      context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(feedProvider.notifier).deletePost(post.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await confirm(
      context,
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _notifier.deleteComment(commentId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postDetailsProvider(widget.postId));
    final me = ref.watch(currentUserIdProvider);

    return post.when(
      loading:
          () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () =>
                            ref.invalidate(postDetailsProvider(widget.postId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: (data) => _content(data, me),
    );
  }

  Widget _content(Post post, int? me) {
    final palette = context.palette;
    final author = post.author;
    final isLiked = me != null && post.isLikedBy(me);
    final hasPhoto = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final likes = likesLine(post, me ?? 0);
    final saved = ref.watch(savedPostsProvider).contains(post.id);
    final myUser =
        me == null ? null : ref.watch(profileProvider(me)).valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          // Same Edit / Delete as on the feed, for the post's owner.
          if (me != null && post.userId == me)
            IconButton(
              tooltip: 'Post options',
              icon: const Icon(Icons.more_horiz),
              onPressed:
                  () => showPostMenu(
                    context,
                    isMine: true,
                    onOpen: () {},
                    onEdit: () => _editPost(post),
                    onDelete: () => _deletePost(post),
                  ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: RefreshIndicator(
                onRefresh: _notifier.reload,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  AppRoutes.profile(post.userId),
                                ),
                            child: UserAvatar(
                              name: author?.name ?? 'User',
                              blob: author?.profilePicBlob,
                              imageUrl: author?.profilePic,
                              radius: 16,
                              backgroundColor: palette.avatarBg,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            author?.name ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onDoubleTap: () {
                        if (!isLiked) _toggleLike();
                      },
                      child: PostMedia(
                        post: post,
                        onPhotoTap:
                            hasPhoto
                                ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ImagePreviewScreen(
                                          imageUrls: [post.imageUrl!],
                                          initialIndex: 0,
                                        ),
                                  ),
                                )
                                : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                      child: Row(
                        children: [
                          CountedIconButton(
                            tooltip: 'Like',
                            onPressed: _toggleLike,
                            count: post.likes.length,
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color:
                                  isLiked
                                      ? palette.heart
                                      : Theme.of(context).colorScheme.onSurface,
                              size: 26,
                            ),
                          ),
                          CountedIconButton(
                            tooltip: 'Comments',
                            onPressed: null,
                            count: post.comments.length,
                            icon: const Icon(
                              Icons.mode_comment_outlined,
                              size: 24,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Share',
                            onPressed: () {
                              if (_requireLogin('share posts')) {
                                showShareSheet(context, post);
                              }
                            },
                            icon: const Icon(Icons.send_outlined, size: 24),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: saved ? 'Remove from saved' : 'Save',
                            onPressed: () => _toggleSave(post.id),
                            icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_border,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (likes.isNotEmpty)
                            Text(
                              likes,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          if (hasPhoto && post.content.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: author?.name ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' ${post.content}'),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timeAgoLabel(post.createdAt),
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 10,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (post.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No comments yet. Start the conversation.',
                          style: TextStyle(color: palette.muted),
                        ),
                      ),
                    for (final comment in post.comments)
                      CommentTile(
                        comment: comment,
                        // The post's owner can remove anyone's comment; others only their own.
                        onDelete:
                            canDeleteComment(
                                  post: post,
                                  comment: comment,
                                  me: me,
                                )
                                ? () => _deleteComment(comment.id)
                                : null,
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 8),
              child: Row(
                children: [
                  UserAvatar(
                    name: myUser?.name ?? '?',
                    imageUrl: myUser?.profilePic,
                    blob: myUser?.profilePicBlob,
                    radius: 16,
                    backgroundColor: palette.avatarBg,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: palette.muted),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  TextButton(onPressed: _addComment, child: const Text('Post')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
