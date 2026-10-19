import 'package:flutter/material.dart';

/// A post photo shown at its own shape (never cropped to a square) and decoded at
/// the sharpness the screen can display. Very tall photos are capped in height and
/// letterboxed instead of cropped.
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
              child: Image.network(
                url,
                width: width,
                fit: BoxFit.contain,
                cacheWidth: (width * pixelRatio).round(),
                filterQuality: FilterQuality.medium,
                loadingBuilder:
                    (context, child, progress) =>
                        progress == null
                            ? child
                            : AspectRatio(
                              aspectRatio: 4 / 3,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                errorBuilder:
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
