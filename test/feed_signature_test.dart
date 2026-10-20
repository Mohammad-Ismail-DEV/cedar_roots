import 'package:cedar_roots/features/feed/feed_provider.dart';
import 'package:cedar_roots/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

PostFeedItem post({int likes = 0, int comments = 0, String content = 'hi'}) =>
    PostFeedItem(
      Post(
        id: 1,
        userId: 2,
        content: content,
        likes: [for (var i = 0; i < likes; i++) Like(userId: i)],
        comments: [
          for (var i = 0; i < comments; i++)
            Comment(id: i, userId: 1, postId: 1, content: 'c$i'),
        ],
      ),
    );

void main() {
  test('identical feeds have the same signature', () {
    expect(feedSignature([post()]), feedSignature([post()]));
  });

  test('a new like, comment, edit or post changes the signature', () {
    final base = feedSignature([post()]);
    expect(feedSignature([post(likes: 1)]), isNot(base));
    expect(feedSignature([post(comments: 1)]), isNot(base));
    expect(feedSignature([post(content: 'edited')]), isNot(base));
    expect(feedSignature([post(), post()]), isNot(base));
  });
}
