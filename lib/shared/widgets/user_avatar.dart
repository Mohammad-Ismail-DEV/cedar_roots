import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Decodes server-rendered base64 avatars once. Small and bounded: the
/// least recently used entries are dropped.
class _BlobCache {
  static const _maxEntries = 150;
  static final _entries = LinkedHashMap<String, Uint8List>();

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

/// The one avatar used everywhere: prefers the small pre-rendered blob, then the
/// full image URL, then the user's initial.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.blob,
    this.radius = 20,
    this.backgroundColor = Colors.blue,
  });

  final String name;
  final String? imageUrl;
  final String? blob;
  final double radius;
  final Color backgroundColor;

  ImageProvider? _provider() {
    final blobBytes =
        (blob != null && blob!.isNotEmpty) ? _BlobCache.decode(blob!) : null;
    if (blobBytes != null) return MemoryImage(blobBytes);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('data:image/')) {
        final bytes = _BlobCache.decode(imageUrl!);
        return bytes == null ? null : MemoryImage(bytes);
      }
      return NetworkImage(imageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider();
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
