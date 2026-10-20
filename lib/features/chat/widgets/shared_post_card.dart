import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/image_url.dart';
import '../../../core/theme.dart';
import '../../../data/post_repository.dart';
import '../../../models/post.dart';
import '../../../shared/widgets/post_media.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../shell/app_routes.dart';

final sharedPostProvider = FutureProvider.autoDispose.family<Post, int>(
  (ref, postId) => ref.read(postRepositoryProvider).getById(postId),
);

/// A post someone sent in chat: author, a thumbnail or the first words, and a tap to open it.
class SharedPostCard extends ConsumerWidget {
  const SharedPostCard({super.key, required this.postId, this.footer});

  final int postId;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final post = ref.watch(sharedPostProvider(postId));
    final width = MediaQuery.sizeOf(context).width * 0.62;

    Widget shell(Widget child) => Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    return post.when(
      loading:
          () => shell(
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      error:
          (_, __) => shell(
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'This post is no longer available',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ),
            ),
          ),
      data: (p) {
        final hasPhoto = p.imageUrl != null && p.imageUrl!.isNotEmpty;
        final author = p.author;

        return GestureDetector(
          onTap: () => Navigator.push(context, AppRoutes.post(p.id)),
          child: shell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: author?.name ?? '?',
                        imageUrl: author?.profilePic,
                        blob: author?.profilePicBlob,
                        radius: 12,
                        backgroundColor: palette.avatarBg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          author?.name ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPhoto)
                  SizedBox(
                    height: width,
                    width: width,
                    child: CachedNetworkImage(
                      httpHeaders: imageHeaders,
                      imageUrl: sizedImageUrl(
                        p.imageUrl!,
                        logicalWidth: width,
                        pixelRatio: MediaQuery.devicePixelRatioOf(context),
                      ),
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => ColoredBox(color: palette.inputBg),
                      errorWidget:
                          (_, __, ___) => ColoredBox(
                            color: palette.inputBg,
                            child: const Icon(Icons.broken_image),
                          ),
                    ),
                  )
                else
                  Container(
                    width: width,
                    height: width * 0.6,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: textGradientFor(p.userId),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.content,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                if (hasPhoto && p.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: footer,
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
