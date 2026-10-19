import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../models/post.dart';
import '../../shared/widgets/post_image.dart';
import '../../shared/widgets/user_avatar.dart';
import '../chat/image_preview_screen.dart';
import '../feed/feed_provider.dart';
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

  String _formatDate(DateTime? date) =>
      date == null ? '' : DateFormat('yMMMd • h:mm a').format(date);

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
    final author = post.author;
    final isLiked = me != null && post.isLikedBy(me);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          // Same Edit / Delete menu as on the feed card, for the post's owner.
          if (me != null && post.userId == me)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editPost(post);
                if (value == 'delete') _deletePost(post);
              },
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: RefreshIndicator(
          onRefresh: _notifier.reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: author?.name ?? 'User',
                    blob: author?.profilePicBlob,
                    imageUrl: author?.profilePic,
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    author?.name ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                PostImage(
                  url: post.imageUrl!,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ImagePreviewScreen(
                                imageUrls: [post.imageUrl!],
                                initialIndex: 0,
                              ),
                        ),
                      ),
                ),
              const SizedBox(height: 12),
              Text(post.content),
              const SizedBox(height: 8),
              Text(
                _formatDate(post.createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                  Text('${post.likes.length} likes'),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _comment,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _addComment(),
              ),
              const SizedBox(height: 12),
              for (final comment in post.comments)
                CommentTile(
                  comment: comment,
                  // The post's owner can remove anyone's comment; others only their own.
                  onDelete:
                      canDeleteComment(post: post, comment: comment, me: me)
                          ? () => _deleteComment(comment.id)
                          : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
