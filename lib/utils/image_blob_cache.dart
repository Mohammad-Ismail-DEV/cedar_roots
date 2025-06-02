import 'dart:typed_data';

class ImageBlobCache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? get(String key) => _cache[key];

  static void set(String key, Uint8List value) {
    _cache[key] = value;
  }
}
