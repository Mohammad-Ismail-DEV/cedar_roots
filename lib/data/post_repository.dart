import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/local_cache.dart';
import '../core/providers.dart';
import '../models/json_helpers.dart';
import '../models/post.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheProvider),
  ),
);

class PostRepository {
  PostRepository(this._api, this._cache);

  final ApiClient _api;
  final LocalCache _cache;

  static const _feedKey = 'posts';
  static const _cachedPosts = 30;

  List<Post>? cachedFeed() {
    final cached = _cache.read(_feedKey);
    return cached == null
        ? null
        : asMapList(cached).map(Post.fromJson).toList();
  }

  Future<List<Post>> fetchFeed({int? userId}) async {
    final data = await _api.get('/posts', query: {'user_id': userId});
    final list = asMapList(data);
    await _cache.write(_feedKey, list.take(_cachedPosts).toList());
    return list.map(Post.fromJson).toList();
  }

  Future<List<Post>> fetchByAuthor(int authorId) async {
    final data = await _api.get('/posts', query: {'author_id': authorId});
    return asMapList(data).map(Post.fromJson).toList();
  }

  Future<Post> getById(int id) async =>
      Post.fromJson(asMap(await _api.get('/posts/$id'))!);

  Future<void> create({required String content, String? imageUrl}) =>
      _api.post('/posts', body: {'content': content, 'image_url': imageUrl});

  /// Sends both fields; a null [imageUrl] removes the post's image.
  Future<void> update(
    int id, {
    required String content,
    required String? imageUrl,
  }) =>
      _api.put('/posts/$id', body: {'content': content, 'image_url': imageUrl});

  Future<void> delete(int id) => _api.delete('/posts/$id');

  /// Returns true when the post is now liked.
  Future<bool> toggleLike(int postId) async {
    final data = await _api.post('/posts/$postId/like');
    return asMap(data)?['liked'] == true;
  }

  // ---- saved posts (kept on the server so they follow you between devices)

  /// Ids of the posts I saved, newest first.
  Future<List<int>> savedIds() async {
    final data = await _api.get('/posts/saved/ids');
    return data is List ? [for (final id in data) asInt(id)] : const [];
  }

  Future<List<Post>> savedPosts() async {
    final data = await _api.get('/posts/saved');
    return asMapList(data).map(Post.fromJson).toList();
  }

  /// Returns true when the post is now saved.
  Future<bool> toggleSave(int postId) async =>
      asMap(await _api.post('/posts/$postId/save'))?['saved'] == true;

  Future<void> addComment(int postId, String content) =>
      _api.post('/comments', body: {'post_id': postId, 'content': content});

  Future<void> deleteComment(int commentId) =>
      _api.delete('/comments/$commentId');

  Future<List<Comment>> comments(int postId) async {
    final data = await _api.get('/comments/post/$postId');
    return asMapList(data).map(Comment.fromJson).toList();
  }
}
