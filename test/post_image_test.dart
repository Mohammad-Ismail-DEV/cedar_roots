import 'package:cached_network_image/cached_network_image.dart';
import 'package:cedar_roots/shared/widgets/post_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const upload = 'http://localhost:3000/uploads/photo.jpg';

Future<void> pump(
  WidgetTester tester, {
  String url = upload,
  double width = 360,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: PostImage(url: url, onTap: () {}),
        ),
      ),
    ),
  );
}

CachedNetworkImage imageWidget(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

void main() {
  testWidgets('shows the whole photo instead of cropping it to a square', (
    tester,
  ) async {
    await pump(tester);

    final image = imageWidget(tester);
    expect(image.fit, BoxFit.contain, reason: 'cover would crop');
    expect(
      image.height,
      isNull,
      reason: 'height follows the photo, not a fixed square',
    );
  });

  testWidgets(
    'downloads a screen-sized copy, not the multi-megabyte original',
    (tester) async {
      await pump(tester, width: 360);

      // (360 - 24 padding) dp at 3x = 1008 px, so the 1080 px copy.
      expect(imageWidget(tester).imageUrl, '$upload?w=1080');
    },
  );

  testWidgets('decodes at the sharpness the screen can show', (tester) async {
    await pump(tester, width: 360);

    expect(imageWidget(tester).memCacheWidth, 336 * 3);
  });

  testWidgets('photos hosted elsewhere are requested as they are', (
    tester,
  ) async {
    await pump(tester, url: 'https://example.com/pic.jpg');

    expect(imageWidget(tester).imageUrl, 'https://example.com/pic.jpg');
  });

  testWidgets('is tappable', (tester) async {
    await pump(tester);

    expect(find.byType(GestureDetector), findsWidgets);
  });
}
