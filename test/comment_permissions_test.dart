import 'package:cedar_roots/features/feed/widgets/comment_tile.dart';
import 'package:cedar_roots/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

// Post 1 belongs to user 10; the comment on it was written by user 20.
const post = Post(id: 1, userId: 10, content: 'hello');
const comment = Comment(id: 5, userId: 20, postId: 1, content: 'nice');

void main() {
  test('the post owner can delete anyone\'s comment', () {
    expect(canDeleteComment(post: post, comment: comment, me: 10), isTrue);
  });

  test('the comment\'s author can delete their own comment', () {
    expect(canDeleteComment(post: post, comment: comment, me: 20), isTrue);
  });

  test('someone else cannot', () {
    expect(canDeleteComment(post: post, comment: comment, me: 30), isFalse);
  });

  test('a guest cannot', () {
    expect(canDeleteComment(post: post, comment: comment, me: null), isFalse);
  });
}
