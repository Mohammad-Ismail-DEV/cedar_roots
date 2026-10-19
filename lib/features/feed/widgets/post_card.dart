import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/post.dart';
import '../../../shared/widgets/post_image.dart';
import '../../../shared/widgets/user_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onOpen,
    required this.onLike,
    required this.onComment,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;

  /// 0 when browsing as a guest.
  final int currentUserId;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUserId);
    final author = post.author;
    final time =
        post.createdAt == null
            ? ''
            : DateFormat('yyyy-MM-dd hh:mm a').format(post.createdAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: author?.name ?? '?',
                blob: author?.profilePicBlob,
                imageUrl: author?.profilePic,
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(
                author?.name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (post.userId == currentUserId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                ),
            ],
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PostImage(url: post.imageUrl!, onTap: onOpen),
            ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: onOpen,
                child: Text(post.content, style: const TextStyle(fontSize: 16)),
              ),
            ),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Text('${post.likes.length}'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${post.comments.length}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
