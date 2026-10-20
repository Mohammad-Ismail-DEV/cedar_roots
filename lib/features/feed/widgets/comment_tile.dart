import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/time_label.dart';
import '../../../models/post.dart';
import '../../../shared/widgets/user_avatar.dart';

/// One comment, identical in the comments sheet and on the post page.
/// [onDelete] is null when the viewer may not delete it (only the comment's author
/// and the post's owner can).
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.onDelete});

  final Comment comment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final author = comment.author;
    final name = author?.name ?? 'User';
    final time = shortAgo(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: name,
            blob: author?.profilePicBlob,
            imageUrl: author?.profilePic,
            radius: 17,
            backgroundColor: palette.avatarBg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' ${comment.content}'),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                  if (time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        time,
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete comment',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 18, color: palette.muted),
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Whether [me] may delete [comment] on [post]: the comment's author or the post's owner.
bool canDeleteComment({
  required Post post,
  required Comment comment,
  int? me,
}) => me != null && (comment.userId == me || post.userId == me);
