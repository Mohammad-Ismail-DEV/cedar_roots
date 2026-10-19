import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/image_url.dart';

/// A post photo shown at its own shape (never cropped to a square). It asks the server for a
/// copy sized for this screen (tens of KB, not the multi-MB original), keeps it on disk so it
/// is instant next time, and caps very tall photos in height instead of cropping them.
class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.url, this.onTap});

  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screen.height * 0.75),
              child: CachedNetworkImage(
                imageUrl: sizedImageUrl(
                  url,
                  logicalWidth: width,
                  pixelRatio: pixelRatio,
                ),
                width: width,
                fit: BoxFit.contain,
                memCacheWidth: (width * pixelRatio).round(),
                filterQuality: FilterQuality.medium,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder:
                    (_, __) => const AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (_, __, ___) => const AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
