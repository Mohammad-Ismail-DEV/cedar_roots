import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final author = comment.author;

    return ListTile(
      leading: UserAvatar(
        name: author?.name ?? 'User',
        blob: author?.profilePicBlob,
        imageUrl: author?.profilePic,
        backgroundColor: Colors.grey,
      ),
      title: Text(
        author?.name ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content),
          if (comment.createdAt != null)
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing:
          onDelete == null
              ? null
              : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete comment',
                onPressed: onDelete,
              ),
      isThreeLine: true,
    );
  }
}

/// Whether [me] may delete [comment] on [post]: the comment's author or the post's owner.
bool canDeleteComment({
  required Post post,
  required Comment comment,
  int? me,
}) => me != null && (comment.userId == me || post.userId == me);
