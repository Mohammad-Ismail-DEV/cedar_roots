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

  Future<Post> getById(int id) async =>
      Post.fromJson(asMap(await _api.get('/posts/$id'))!);

  Future<void> create({required String content, String? imageUrl}) =>
      _api.post('/posts', body: {'content': content, 'image_url': imageUrl});

  Future<void> update(int id, {String? content, String? imageUrl}) => _api.put(
    '/posts/$id',
    body: {
      if (content != null) 'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    },
  );

  Future<void> delete(int id) => _api.delete('/posts/$id');

  /// Returns true when the post is now liked.
  Future<bool> toggleLike(int postId) async {
    final data = await _api.post('/posts/$postId/like');
    return asMap(data)?['liked'] == true;
  }

  Future<void> addComment(int postId, String content) =>
      _api.post('/comments', body: {'post_id': postId, 'content': content});

  Future<void> deleteComment(int commentId) =>
      _api.delete('/comments/$commentId');

  Future<List<Comment>> comments(int postId) async {
    final data = await _api.get('/comments/post/$postId');
    return asMapList(data).map(Comment.fromJson).toList();
  }
}
