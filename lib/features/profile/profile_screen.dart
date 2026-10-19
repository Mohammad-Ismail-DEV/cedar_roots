import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/image_url.dart';
import '../../core/photo_crop.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../models/connection.dart';
import '../../models/post.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../feed/widgets/comment_sheet.dart';
import '../feed/widgets/post_card.dart';
import '../settings/settings_screen.dart';
import '../shell/app_routes.dart';
import 'profile_provider.dart';
import 'widgets/profile_header.dart';

/// A user's profile. With no [userId] it shows the signed-in user's own profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return const SignInRequired(message: 'Log in to see your profile.');
    }
    return _Profile(userId: userId ?? me, myUserId: me);
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.userId, required this.myUserId});

  final int userId;
  final int myUserId;

  bool get _isMine => userId == myUserId;

  ProfileNotifier _notifier(WidgetRef ref) =>
      ref.read(profileProvider(userId).notifier);

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _changePicture(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await cropPhoto(picked.path);
    if (cropped == null || !context.mounted) return;

    await _run(
      context,
      () => _notifier(ref).changeProfilePicture(XFile(cropped.path)),
    );
  }

  void _showAvatar(BuildContext context, WidgetRef ref, String? url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child:
                        url != null && url.isNotEmpty
                            ? CachedNetworkImage(
                              httpHeaders: imageHeaders,
                              imageUrl: sizedImageUrl(
                                url,
                                logicalWidth: MediaQuery.sizeOf(ctx).width,
                                pixelRatio: MediaQuery.devicePixelRatioOf(ctx),
                              ),
                              fit: BoxFit.contain,
                            )
                            : const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            ),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (_isMine)
                    Positioned(
                      top: 40,
                      right: 20,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _changePicture(context, ref);
                        },
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _connectionActions(
    BuildContext context,
    WidgetRef ref,
    ProfileData data,
  ) {
    final notifier = _notifier(ref);

    return switch (data.status) {
      ConnectionStatus.accepted => ShadowButton(
        label: 'Remove Connection',
        color: Colors.red,
        onTap: () => _run(context, notifier.disconnect),
      ),
      ConnectionStatus.pendingSent => ShadowButton(
        label: 'Cancel Request',
        color: Colors.red,
        onTap: () => _run(context, notifier.disconnect),
      ),
      ConnectionStatus.pendingReceived => Row(
        children: [
          Expanded(
            child: ShadowButton(
              label: 'Accept',
              onTap: () => _run(context, () => notifier.respond(accept: true)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShadowButton(
              label: 'Reject',
              color: Colors.red,
              onTap: () => _run(context, () => notifier.respond(accept: false)),
            ),
          ),
        ],
      ),
      ConnectionStatus.none => ShadowButton(
        label: 'Connect',
        onTap: () => _run(context, notifier.connect),
      ),
    };
  }

  Widget _chatButton(BuildContext context, ProfileData data) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              AppRoutes.chat(userId: userId, name: data.user.name),
            ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Center(child: Icon(Icons.chat, color: Colors.green)),
        ),
      ),
    );
  }

  Widget _posts(BuildContext context, WidgetRef ref, ProfileData data) {
    if (data.posts.isEmpty) return const Center(child: Text('No posts yet.'));

    final notifier = _notifier(ref);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: data.posts.length,
      itemBuilder: (context, index) {
        final Post post = data.posts[index];
        return PostCard(
          post: post,
          currentUserId: myUserId,
          onOpen:
              () => Navigator.push(
                context,
                AppRoutes.post(post.id),
              ).then((_) => notifier.reloadPosts()),
          onLike: () => _run(context, () => notifier.toggleLike(post.id)),
          onComment:
              () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CommentSheet(postId: post.id),
              ).then((_) => notifier.reloadPosts()),
          onEdit:
              () => Navigator.push(
                context,
                AppRoutes.createPost(editing: post),
              ).then((_) => notifier.reloadPosts()),
          onDelete: () async {
            final confirmed = await confirm(
              context,
              title: 'Delete Post',
              message: 'Are you sure you want to delete this post?',
              confirmLabel: 'Delete',
              destructive: true,
            );
            if (confirmed && context.mounted) {
              await _run(context, () => notifier.deletePost(post.id));
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(userId));

    return profile.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed: () => ref.invalidate(profileProvider(userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      data: (data) => _loaded(context, ref, data),
    );
  }

  Widget _loaded(BuildContext context, WidgetRef ref, ProfileData data) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          ProfileHeader(
            user: data.user,
            connectionsCount: data.connectionsCount,
            onConnectionsTap:
                () => Navigator.push(context, AppRoutes.connections(userId)),
            onSettingsTap:
                _isMine
                    ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    )
                    : null,
            onAvatarTap: () => _showAvatar(context, ref, data.user.profilePic),
          ),
          if (!_isMine)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.status == ConnectionStatus.accepted) ...[
                      _chatButton(context, data),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: _connectionActions(context, ref, data)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ShadowButton(
                label: 'Manage Organizations',
                icon: Icons.admin_panel_settings,
                color: const Color(0xFF0B1E3A),
                onTap:
                    () => Navigator.push(
                      context,
                      AppRoutes.organizations(userId),
                    ),
              ),
            ),
          const Divider(),
          Expanded(child: _posts(context, ref, data)),
        ],
      ),
      floatingActionButton:
          _isMine
              ? SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        AppRoutes.createPost(),
                      ).then((_) => _notifier(ref).reloadPosts()),
                  icon: const Icon(Icons.add, color: Colors.blue, size: 26),
                  label: const Text(
                    'Create Post',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
