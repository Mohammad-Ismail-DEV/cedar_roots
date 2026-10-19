import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/session.dart';
import '../../data/connection_repository.dart';
import '../../data/media_repository.dart';
import '../../data/post_repository.dart';
import '../../data/user_repository.dart';
import '../../models/connection.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../feed/feed_provider.dart';

class ProfileData {
  const ProfileData({
    required this.user,
    required this.connectionsCount,
    required this.status,
    required this.posts,
  });

  final User user;
  final int connectionsCount;
  final ConnectionStatus status;
  final List<Post> posts;

  ProfileData copyWith({
    User? user,
    int? connectionsCount,
    ConnectionStatus? status,
    List<Post>? posts,
  }) => ProfileData(
    user: user ?? this.user,
    connectionsCount: connectionsCount ?? this.connectionsCount,
    status: status ?? this.status,
    posts: posts ?? this.posts,
  );
}

/// A user's profile: details, connection state with me, and their posts.
/// The argument is the profile owner's user id.
final profileProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileNotifier, ProfileData, int>(ProfileNotifier.new);

class ProfileNotifier extends AutoDisposeFamilyAsyncNotifier<ProfileData, int> {
  PostRepository get _posts => ref.read(postRepositoryProvider);
  ConnectionRepository get _connections =>
      ref.read(connectionRepositoryProvider);
  int? get _me => ref.read(currentUserIdProvider);

  @override
  Future<ProfileData> build(int arg) async {
    final me = ref.watch(currentUserIdProvider);
    final isMe = me == arg;

    final (user, count, status, posts) =
        await (
          ref.read(userRepositoryProvider).getById(arg),
          _connections.acceptedCount(arg),
          me != null && !isMe
              ? _connections.statusBetween(me, arg)
              : Future.value(ConnectionStatus.none),
          _posts.fetchByAuthor(arg),
        ).wait;

    return ProfileData(
      user: user,
      connectionsCount: count,
      status: status,
      posts: posts,
    );
  }

  Future<void> reloadPosts() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(posts: await _posts.fetchByAuthor(arg)));
  }

  Future<void> reloadConnection() async {
    final current = state.valueOrNull;
    final me = _me;
    if (current == null || me == null || me == arg) return;
    final (count, status) =
        await (
          _connections.acceptedCount(arg),
          _connections.statusBetween(me, arg),
        ).wait;
    state = AsyncData(
      current.copyWith(connectionsCount: count, status: status),
    );
  }

  // ---- connection with this user

  Future<void> connect() async {
    await _connections.request(arg);
    await reloadConnection();
  }

  /// Cancels a pending request or removes an accepted connection.
  Future<void> disconnect() async {
    final connection = await _connections.between(_me!, arg);
    if (connection != null) await _connections.remove(connection.id);
    await reloadConnection();
  }

  Future<void> respond({required bool accept}) async {
    final connection = await _connections.between(_me!, arg);
    if (connection != null) {
      await _connections.respond(connection.id, accept: accept);
    }
    await reloadConnection();
  }

  // ---- posts

  Future<void> toggleLike(int postId) async {
    final me = _me;
    final before = state.valueOrNull;
    if (me == null || before == null) return;

    Post? updated;
    state = AsyncData(
      before.copyWith(
        posts: [
          for (final p in before.posts)
            if (p.id == postId)
              updated = p.copyWith(
                likes:
                    p.isLikedBy(me)
                        ? p.likes.where((l) => l.userId != me).toList()
                        : [...p.likes, Like(userId: me)],
              )
            else
              p,
        ],
      ),
    );

    try {
      await _posts.toggleLike(postId);
      if (updated != null) ref.read(feedProvider.notifier).replacePost(updated);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> deletePost(int postId) async {
    await ref.read(feedProvider.notifier).deletePost(postId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        posts: current.posts.where((p) => p.id != postId).toList(),
      ),
    );
  }

  // ---- own avatar

  Future<void> changeProfilePicture(XFile file) async {
    final me = _me;
    if (me == null || me != arg) return;
    final url = await ref.read(mediaRepositoryProvider).uploadImage(file);
    await ref.read(userRepositoryProvider).update(me, profilePic: url);

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        user: await ref.read(userRepositoryProvider).getById(me),
      ),
    );
  }
}
