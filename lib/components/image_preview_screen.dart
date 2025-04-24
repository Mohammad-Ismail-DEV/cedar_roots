import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ImagePreviewScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImagePreviewScreen({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  Future<void> _saveImage(BuildContext context, String url) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Permission denied")));
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = Directory('/storage/emulated/0/Pictures/CedarRoots');
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to gallery')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving image: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(0, 0, 0, 0.85),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            pageController: PageController(initialPage: initialIndex),
            builder:
                (context, index) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrls[index]),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: imageUrls[index],
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 2.0,
                ),
            loadingBuilder:
                (context, event) => Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.download, color: Colors.white),
              onPressed: () => _saveImage(context, imageUrls[initialIndex]),
            ),
          ),
        ],
      ),
    );
  }
}
