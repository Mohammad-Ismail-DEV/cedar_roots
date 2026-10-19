import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../core/image_url.dart';
import '../../core/ui.dart';

/// Full-screen swipeable gallery with a "save to gallery" button.
class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrls[_current]));
      if (response.statusCode != 200) throw Exception('download failed');
      await Gal.putImageBytes(response.bodyBytes);
      if (mounted) showSnack(context, 'Saved to gallery');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not save the image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.85),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.imageUrls.length,
            pageController: _pages,
            onPageChanged: (index) => setState(() => _current = index),
            builder:
                (context, index) => PhotoViewGalleryPageOptions(
                  // The original, at full resolution, so zooming stays sharp.
                  imageProvider: CachedNetworkImageProvider(
                    headers: imageHeaders,
                    resolveUploadUrl(widget.imageUrls[index]),
                  ),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: widget.imageUrls[index],
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 4.0,
                ),
            // While the original downloads, show the screen-sized copy that is
            // usually already cached from the feed, so something appears at once.
            loadingBuilder:
                (context, event) => Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      httpHeaders: imageHeaders,
                      imageUrl: sizedImageUrl(
                        widget.imageUrls[_current],
                        logicalWidth: MediaQuery.sizeOf(context).width,
                        pixelRatio: MediaQuery.devicePixelRatioOf(context),
                      ),
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const Positioned(
                      bottom: 40,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                ),
          ),
          Positioned(
            top: 40,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _save,
              ),
            ),
        ],
      ),
    );
  }
}
