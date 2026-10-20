import 'config.dart';

/// Sizes the server can produce (must match backend/src/middleware/imageVariants.js).
const _widths = [128, 256, 512, 768, 1080, 1600];

/// The URL of a smaller copy of one of our own uploaded photos, sized for the space it will
/// fill: a feed photo is ~50 KB instead of the multi-megabyte original. Any other URL (or one
/// that is not ours) is returned unchanged. Sizes are snapped to the server's list so every
/// caller asks for the same URL and the on-disk cache is reused.
String sizedImageUrl(
  String url, {
  required double logicalWidth,
  required double pixelRatio,
}) {
  final resolved = resolveUploadUrl(url);
  final uri = Uri.tryParse(resolved);
  if (uri == null || !uri.path.startsWith('/uploads/')) return resolved;

  final needed = logicalWidth * pixelRatio;
  final width = _widths.firstWhere(
    (w) => w >= needed,
    orElse: () => _widths.last,
  );
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'w': '$width'})
      .toString();
}

/// Headers for loading our own images. ngrok's free tier answers browsers with an HTML warning
/// page unless this header is present, which shows up as a broken image on Flutter web.
Map<String, String>? get imageHeaders =>
    AppConfig.apiUrl.contains('ngrok')
        ? const {'ngrok-skip-browser-warning': 'true'}
        : null;

/// Uploaded photos are stored with the address the sender used (localhost, an emulator, a LAN
/// IP or the ngrok domain), which another device or build may not be able to reach. Every
/// photo of ours lives on the one server this app talks to, so point `/uploads/` URLs at it.
/// Anything else is returned untouched.
String resolveUploadUrl(String url, {String? apiUrl}) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.startsWith('/uploads/')) return url;
  final api = Uri.tryParse(apiUrl ?? AppConfig.apiUrl);
  if (api == null || api.host.isEmpty) return url;
  if (api.scheme == uri.scheme &&
      api.host == uri.host &&
      (api.hasPort ? api.port : null) == (uri.hasPort ? uri.port : null)) {
    return url;
  }
  // Built from scratch: Uri.replace would keep the old port when the new address has none.
  return Uri(
    scheme: api.scheme,
    host: api.host,
    port: api.hasPort ? api.port : null,
    path: uri.path,
    query: uri.hasQuery ? uri.query : null,
  ).toString();
}
