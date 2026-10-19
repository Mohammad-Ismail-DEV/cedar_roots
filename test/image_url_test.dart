import 'package:cedar_roots/core/image_url.dart';
import 'package:flutter_test/flutter_test.dart';

const upload = 'https://example.ngrok-free.app/uploads/photo.jpg';

String sized(String url, double logicalWidth, [double pixelRatio = 3]) =>
    sizedImageUrl(url, logicalWidth: logicalWidth, pixelRatio: pixelRatio);

void main() {
  test('asks for the smallest server size that is sharp enough', () {
    expect(sized(upload, 336), '$upload?w=1080');
    expect(sized(upload, 72), '$upload?w=256');
    expect(sized(upload, 40), '$upload?w=128');
    expect(sized(upload, 200), '$upload?w=768');
  });

  test('never asks for more than the largest size', () {
    expect(sized(upload, 2000), '$upload?w=1600');
  });

  test('similar screen widths snap to one URL so the disk cache is reused', () {
    final urls = {
      for (final w in [330.0, 334.0, 336.0, 340.0]) sized(upload, w),
    };
    expect(urls, hasLength(1));
  });

  test('leaves URLs that are not our uploads alone', () {
    expect(
      sized('https://example.com/pic.jpg', 300),
      'https://example.com/pic.jpg',
    );
    expect(sized('not a url at all', 300), 'not a url at all');
  });

  test('keeps any other query parameters', () {
    expect(sized('$upload?v=2', 336), '$upload?v=2&w=1080');
  });
}
