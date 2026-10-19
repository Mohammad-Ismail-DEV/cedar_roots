import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Decodes server-rendered base64 avatars once. Small and bounded: the
/// least recently used entries are dropped.
class _BlobCache {
  static const _maxEntries = 150;
  static final _entries = <String, Uint8List>{};

  static Uint8List? decode(String dataUri) {
    final cached = _entries.remove(dataUri);
    if (cached != null) {
      _entries[dataUri] = cached;
      return cached;
    }

    final comma = dataUri.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(dataUri.substring(comma + 1));
      _entries[dataUri] = bytes;
      if (_entries.length > _maxEntries) _entries.remove(_entries.keys.first);
      return bytes;
    } on FormatException {
      return null;
    }
  }
}

/// The one avatar used everywhere. Small avatars use the server's tiny pre-rendered
/// preview (fast in lists); large ones (profile pages) load the full photo and show
/// the preview only while it downloads, because stretching a preview looks blurry.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.blob,
    this.radius = 20,
    this.backgroundColor = Colors.blue,
  });

  /// Avatars at least this big are shown from the full-resolution image.
  static const _fullImageRadius = 28.0;

  final String name;
  final String? imageUrl;
  final String? blob;
  final double radius;
  final Color backgroundColor;

  bool get _hasNetworkImage =>
      imageUrl != null &&
      imageUrl!.isNotEmpty &&
      !imageUrl!.startsWith('data:image/');

  Widget _fullResolution(BuildContext context) {
    final diameter = radius * 2;
    final pixels = (diameter * MediaQuery.devicePixelRatioOf(context)).round();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Instant placeholder: the preview (or initial), replaced once the photo loads.
        _circle(allowNetwork: false),
        ClipOval(
          child: Image.network(
            imageUrl!,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            cacheWidth: pixels,
            filterQuality: FilterQuality.medium,
            frameBuilder:
                (context, child, frame, wasSynchronouslyLoaded) =>
                    AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    ),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  ImageProvider? _provider({required bool allowNetwork}) {
    final blobBytes =
        (blob != null && blob!.isNotEmpty) ? _BlobCache.decode(blob!) : null;
    if (blobBytes != null) return MemoryImage(blobBytes);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('data:image/')) {
        final bytes = _BlobCache.decode(imageUrl!);
        return bytes == null ? null : MemoryImage(bytes);
      }
      return allowNetwork ? NetworkImage(imageUrl!) : null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (radius >= _fullImageRadius && _hasNetworkImage) {
      return _fullResolution(context);
    }
    return _circle();
  }

  Widget _circle({bool allowNetwork = true}) {
    final provider = _provider(allowNetwork: allowNetwork);
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: provider,
      onBackgroundImageError: provider is NetworkImage ? (_, __) {} : null,
      child:
          provider == null
              ? Text(
                initial,
                style: TextStyle(color: Colors.white, fontSize: radius * 0.8),
              )
              : null,
    );
  }
}
