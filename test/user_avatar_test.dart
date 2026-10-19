import 'package:cached_network_image/cached_network_image.dart';
import 'package:cedar_roots/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const upload = 'https://example.ngrok-free.app/uploads/a.jpg';

Future<void> pump(WidgetTester tester, UserAvatar avatar) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: avatar))),
  );
}

void main() {
  testWidgets('small avatars stay a single cheap circle', (tester) async {
    await pump(
      tester,
      const UserAvatar(name: 'Ada', imageUrl: upload, radius: 20),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('large avatars load a sharp copy sized for the circle', (
    tester,
  ) async {
    await pump(
      tester,
      const UserAvatar(name: 'Ada', imageUrl: upload, radius: 36),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.width, 72);
    expect(image.height, 72);
    expect(
      image.memCacheWidth,
      216,
      reason: 'decoded at display size, not full size',
    );
    expect(
      image.imageUrl,
      '$upload?w=256',
      reason: 'a 216 px circle needs the 256 px copy',
    );
  });

  testWidgets('large avatars show the initial until the photo arrives', (
    tester,
  ) async {
    await pump(
      tester,
      const UserAvatar(name: 'ada', imageUrl: upload, radius: 36),
    );

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('large avatars without a network image are a plain circle', (
    tester,
  ) async {
    await pump(tester, const UserAvatar(name: 'Ada', radius: 36));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
