import 'json_helpers.dart';
import 'user.dart';

class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    this.createdAt,
    this.author,
  });

  final int id;
  final int userId;
  final int postId;
  final String content;
  final DateTime? createdAt;
  final User? author;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: asInt(json['id']),
    userId: asInt(json['user_id']),
    postId: asInt(json['post_id']),
    content: (json['content'] ?? '').toString(),
    createdAt: asDate(json['created_at']),
    author: User.maybe(json['Author']),
  );
}

class Like {
  const Like({required this.userId, this.liker});

  final int userId;
  final User? liker;

  factory Like.fromJson(Map<String, dynamic> json) =>
      Like(userId: asInt(json['user_id']), liker: User.maybe(json['Liker']));
}

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.createdAt,
    this.author,
    this.comments = const [],
    this.likes = const [],
  });

  final int id;
  final int userId;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;
  final User? author;
  final List<Comment> comments;
  final List<Like> likes;

  bool isLikedBy(int userId) => likes.any((l) => l.userId == userId);

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: asInt(json['id']),
    userId: asInt(json['user_id']),
    content: (json['content'] ?? '').toString(),
    imageUrl: asStringOrNull(json['image_url']),
    createdAt: asDate(json['created_at']),
    author: User.maybe(json['User']),
    comments: asMapList(json['Comments']).map(Comment.fromJson).toList(),
    likes: asMapList(json['Likes']).map(Like.fromJson).toList(),
  );
}
