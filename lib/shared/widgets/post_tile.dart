import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/image_url.dart';
import '../../core/theme.dart';
import '../../models/post.dart';
import 'post_media.dart';

/// A square thumbnail of a post for grids: the photo cropped to fill, or the words on a gradient.
class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Semantics(
      button: true,
      label: 'Open post',
      child: GestureDetector(
        onTap: onTap,
        child:
            hasPhoto
                ? CachedNetworkImage(
                  httpHeaders: imageHeaders,
                  imageUrl: sizedImageUrl(
                    post.imageUrl!,
                    logicalWidth: 140,
                    pixelRatio: pixelRatio,
                  ),
                  fit: BoxFit.cover,
                  memCacheWidth: (140 * pixelRatio).round(),
                  placeholder:
                      (_, __) => ColoredBox(color: context.palette.inputBg),
                  errorWidget:
                      (_, __, ___) => ColoredBox(
                        color: context.palette.inputBg,
                        child: const Icon(Icons.broken_image),
                      ),
                )
                : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: textGradientFor(post.userId),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        post.content,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

/// A 3-column grid of [PostTile]s with the hairline gaps used across the app.
class PostGrid extends StatelessWidget {
  const PostGrid({super.key, required this.posts, required this.onOpen});

  final List<Post> posts;
  final void Function(Post post) onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder:
          (_, i) => PostTile(post: posts[i], onTap: () => onOpen(posts[i])),
    );
  }
}
