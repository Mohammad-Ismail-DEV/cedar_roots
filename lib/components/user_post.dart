import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPost extends StatelessWidget {
  final Map<String, dynamic> post;
  final int currentUserId;
  final void Function(int postId) onEdit;
  final void Function(int postId) onDelete;
  final void Function(int postId) onComment;
  final void Function(int postId, bool isLiked) onLike;

  const UserPost({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.onComment,
    required this.onLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLiked =
        (post['Likes'] as List?)?.any(
          (like) => like['user_id'] == currentUserId,
        ) ??
        false;

    final createdAt = DateTime.tryParse(post['created_at'] ?? '');
    final formattedTime =
        createdAt != null
            ? DateFormat('yyyy-MM-dd hh:mm a').format(createdAt.toLocal())
            : '';

    final author = post['User'] ?? {};
    final authorName = author['name'] ?? 'Unknown';
    final profilePic = author['profile_pic'] ?? '';

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
          // Author header
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                backgroundColor: Colors.grey[300],
                child:
                    profilePic.isEmpty
                        ? Text(
                          authorName[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        )
                        : null,
              ),
              SizedBox(width: 10),
              Text(authorName, style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(),
              if (post['user_id'] == currentUserId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit(post['id']);
                    if (value == 'delete') onDelete(post['id']);
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                ),
            ],
          ),
          if (post['image_url'] != null &&
              post['image_url'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post['image_url'] ?? ''),
              ),
            ),
          if (post['content'] != null && post['content'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                post['content'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => onLike(post['id'], isLiked),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              Text('${post['Likes']?.length ?? 0}'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => onComment(post['id']),
                child: Row(
                  children: [
                    const Icon(Icons.comment, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${post['Comments']?.length ?? 0}'),
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
