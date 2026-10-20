import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../shell/app_routes.dart';
import '../post_details_provider.dart';

/// Who liked a post, newest data from the server, tap a person to open their profile.
Future<void> showLikesSheet(BuildContext context, int postId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LikesSheet(postId: postId),
  );
}

class _LikesSheet extends ConsumerWidget {
  const _LikesSheet({required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postDetailsProvider(postId));
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.6;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Likes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: post.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => Center(
                    child: TextButton(
                      onPressed:
                          () => ref.invalidate(postDetailsProvider(postId)),
                      child: const Text('Could not load likes. Retry'),
                    ),
                  ),
              data: (data) {
                final likers = [
                  for (final like in data.likes)
                    if (like.liker != null) like.liker!,
                ];
                if (likers.isEmpty) {
                  return Center(
                    child: Text(
                      'No likes yet',
                      style: TextStyle(color: palette.muted),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: likers.length,
                  itemBuilder: (_, i) {
                    final user = likers[i];
                    return ListTile(
                      leading: UserAvatar(
                        name: user.name,
                        imageUrl: user.profilePic,
                        blob: user.profilePicBlob,
                        radius: 20,
                        backgroundColor: palette.avatarBg,
                      ),
                      title: Text(user.name),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(AppRoutes.profile(user.id));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
