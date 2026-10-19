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
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.startsWith('/uploads/')) return url;

  final needed = logicalWidth * pixelRatio;
  final width = _widths.firstWhere(
    (w) => w >= needed,
    orElse: () => _widths.last,
  );
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'w': '$width'})
      .toString();
}
