import 'package:cedar_roots/core/time_label.dart';
import 'package:cedar_roots/features/feed/likes_line.dart';
import 'package:cedar_roots/models/post.dart';
import 'package:cedar_roots/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

Post post(List<Like> likes) =>
    Post(id: 1, userId: 9, content: 'hi', likes: likes);

Like like(int userId, [String? name]) => Like(
  userId: userId,
  liker: name == null ? null : User(id: userId, name: name),
);

void main() {
  group('timeAgoLabel', () {
    final now = DateTime(2026, 10, 20, 12);

    test('counts up from just now', () {
      expect(timeAgoLabel(now, now: now), 'JUST NOW');
      expect(
        timeAgoLabel(now.subtract(const Duration(minutes: 1)), now: now),
        '1 MINUTE AGO',
      );
      expect(
        timeAgoLabel(now.subtract(const Duration(hours: 2)), now: now),
        '2 HOURS AGO',
      );
      expect(
        timeAgoLabel(now.subtract(const Duration(days: 3)), now: now),
        '3 DAYS AGO',
      );
    });

    test('falls back to a date after a week, and has no label without one', () {
      expect(timeAgoLabel(DateTime(2026, 9, 1), now: now), 'SEPTEMBER 1');
      expect(timeAgoLabel(null), '');
    });
  });

  group('likesLine', () {
    test('is empty when nobody liked it', () {
      expect(likesLine(post([]), 1), '');
    });

    test('says "you" when I liked it', () {
      expect(likesLine(post([like(1)]), 1), 'Liked by you');
      expect(
        likesLine(post([like(1), like(2), like(3)]), 1),
        'Liked by you and 2 others',
      );
      expect(
        likesLine(post([like(1), like(2)]), 1),
        'Liked by you and 1 other',
      );
    });

    test('names the first person otherwise', () {
      expect(likesLine(post([like(2, 'Karim')]), 1), 'Liked by Karim');
      expect(
        likesLine(post([like(2, 'Karim'), like(3, 'Maya')]), 1),
        'Liked by Karim and 1 other',
      );
    });

    test('falls back to a count when no name is known', () {
      expect(likesLine(post([like(2), like(3)]), 1), '2 likes');
    });
  });
}
