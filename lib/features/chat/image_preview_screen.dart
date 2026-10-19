import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: widget.imageUrls[index],
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 2.0,
                ),
            loadingBuilder:
                (context, event) =>
                    const Center(child: CircularProgressIndicator()),
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
