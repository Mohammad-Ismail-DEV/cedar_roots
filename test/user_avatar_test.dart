import 'package:cedar_roots/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, UserAvatar avatar) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: avatar))));

void main() {
  testWidgets('small avatars stay a single cheap circle', (tester) async {
    await pump(
      tester,
      const UserAvatar(
        name: 'Ada',
        imageUrl: 'https://x.test/a.jpg',
        radius: 20,
      ),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('large avatars load the full-resolution photo', (tester) async {
    await pump(
      tester,
      const UserAvatar(
        name: 'Ada',
        imageUrl: 'https://x.test/a.jpg',
        radius: 36,
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 72);
    expect(image.height, 72);
    expect(
      image.image,
      isA<ResizeImage>(),
      reason: 'decoded at display size, not full size',
    );
  });

  testWidgets('large avatars show the initial until the photo arrives', (
    tester,
  ) async {
    await pump(
      tester,
      const UserAvatar(
        name: 'ada',
        imageUrl: 'https://x.test/a.jpg',
        radius: 36,
      ),
    );

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('large avatars without a network image are a plain circle', (
    tester,
  ) async {
    await pump(tester, const UserAvatar(name: 'Ada', radius: 36));

    expect(find.byType(Image), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
