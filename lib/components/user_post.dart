import 'package:cedar_roots/utils/image_blob_cache.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

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

  Future<Uint8List> _loadBlobImage(String blob) async {
    final cached = ImageBlobCache.get(blob);
    if (cached != null) return cached;

    try {
      final decoded = base64Decode(blob.split(',').last);
      ImageBlobCache.set(blob, decoded);
      return decoded;
    } catch (e) {
      throw Exception("Failed to decode base64 image");
    }
  }

  Widget _buildPostImage(BuildContext context) {
    final String? imageUrl = post['image_url'];
    final double imageSize = MediaQuery.of(context).size.width - 24;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: imageSize,
            width: imageSize,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: imageSize,
                width: imageSize,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                height: imageSize,
                width: imageSize,
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

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
    final profilePicBlob = author['profile_pic_blob'];

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
              FutureBuilder<Uint8List>(
                future:
                    profilePicBlob != null
                        ? _loadBlobImage(profilePicBlob)
                        : null,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      profilePicBlob != null) {
                    return const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasData) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: MemoryImage(snapshot.data!),
                    );
                  }

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[400],
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
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
          _buildPostImage(context),

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
