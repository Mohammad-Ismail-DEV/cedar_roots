import 'package:cedar_roots/models/post.dart';
import 'package:cedar_roots/shared/widgets/post_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Post post(String content) =>
    Post(id: 1, userId: 2, content: content, imageUrl: null);

Future<void> show(WidgetTester tester, String content) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: PostMedia(post: post(content))),
    ),
  ),
);

void main() {
  test('short words stay on the gradient square, long ones do not', () {
    expect(isLongPostText('Plant trees on Saturday'), isFalse);
    expect(isLongPostText('a' * 151), isTrue);
    expect(isLongPostText('one\ntwo\nthree\nfour\nfive'), isTrue);
  });

  testWidgets('a short text post is a gradient card', (tester) async {
    await show(tester, 'Short and sweet');
    expect(find.byType(TextPostCard), findsOneWidget);
    expect(find.byType(LongTextPost), findsNothing);
  });

  testWidgets('a long text post shows all of its text as plain text', (
    tester,
  ) async {
    final long = List.generate(30, (i) => 'Sentence number $i.').join(' ');
    await show(tester, long);
    expect(find.byType(TextPostCard), findsNothing);
    expect(find.text(long), findsOneWidget);
  });
}
