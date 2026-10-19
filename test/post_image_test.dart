import 'package:cedar_roots/shared/widgets/post_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, {double width = 360}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: PostImage(url: 'https://x.test/photo.jpg', onTap: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the whole photo instead of cropping it to a square', (
    tester,
  ) async {
    await pump(tester);

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain, reason: 'cover would crop');
    expect(
      image.height,
      isNull,
      reason: 'height follows the photo, not a fixed square',
    );
  });

  testWidgets('decodes at the sharpness the screen can show', (tester) async {
    await pump(tester, width: 360);

    final provider =
        tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    // (360 - 24 padding) dp wide at 3x pixel density.
    expect(provider.width, (336 * 3).round());
  });

  testWidgets('is tappable', (tester) async {
    await pump(tester);

    expect(find.byType(GestureDetector), findsWidgets);
  });
}
