import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/time_label.dart';
import '../../../models/post.dart';
import '../../../shared/widgets/post_media.dart';
import '../../../shared/widgets/ring_avatar.dart';
import '../likes_line.dart';

/// One post in the feed: header, edge-to-edge media, actions, likes, caption and comments link.
/// Double-tap the media to like it.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onOpen,
    required this.onOpenAuthor,
    required this.onViewPhoto,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMenu,
    required this.onSave,
    required this.saved,
    this.hasStory = false,
  });

  final Post post;

  /// 0 when browsing as a guest.
  final int currentUserId;
  final VoidCallback onOpen;
  final VoidCallback onOpenAuthor;
  final VoidCallback onViewPhoto;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onMenu;
  final VoidCallback onSave;
  final bool saved;

  /// The author has something unseen: draw the gradient ring.
  final bool hasStory;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  bool get _liked => widget.post.isLikedBy(widget.currentUserId);

  void _doubleTap() {
    _burst.forward(from: 0);
    if (!_liked) widget.onLike();
  }

  /// Scale and fade of the big heart: pops in, holds, fades out.
  (double scale, double opacity) _burstLook(double t) {
    if (t == 0) return (0.2, 0);
    final scale = t < 0.25 ? 0.2 + (t / 0.25) : 1.2 - (t - 0.25) * 0.27;
    final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    return (scale.clamp(0.0, 2.0), opacity.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).colorScheme.onSurface;
    final post = widget.post;
    final author = post.author;
    final name = author?.name ?? 'Unknown';
    final hasPhoto = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final comments = post.comments.length;
    final likesText = likesLine(widget.post, widget.currentUserId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onOpenAuthor,
                  child: RingAvatar(
                    name: name,
                    imageUrl: author?.profilePic,
                    blob: author?.profilePicBlob,
                    radius: 16,
                    ringed: widget.hasStory,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onOpenAuthor,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Post options',
                  onPressed: widget.onMenu,
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: _doubleTap,
            onTap: hasPhoto ? null : widget.onOpen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PostMedia(post: post, onPhotoTap: widget.onViewPhoto),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) {
                      final (scale, opacity) = _burstLook(_burst.value);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 96,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Like',
                  onPressed: widget.onLike,
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? palette.heart : text,
                    size: 26,
                  ),
                ),
                IconButton(
                  tooltip: 'Comments',
                  onPressed: widget.onComment,
                  icon: const Icon(Icons.mode_comment_outlined, size: 24),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: widget.onShare,
                  icon: const Icon(Icons.send_outlined, size: 24),
                ),
                const Spacer(),
                IconButton(
                  tooltip: widget.saved ? 'Remove from saved' : 'Save',
                  onPressed: widget.onSave,
                  icon: Icon(
                    widget.saved ? Icons.bookmark : Icons.bookmark_border,
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
                if (likesText.isNotEmpty)
                  Text(
                    likesText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                if (hasPhoto && post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: GestureDetector(
                      onTap: widget.onOpen,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' ${post.content}'),
                          ],
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: widget.onComment,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      comments == 0
                          ? 'Add a comment...'
                          : comments == 1
                          ? 'View 1 comment'
                          : 'View all $comments comments',
                      style: TextStyle(color: palette.muted, fontSize: 14),
                    ),
                  ),
                ),
                Text(
                  timeAgoLabel(post.createdAt),
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
