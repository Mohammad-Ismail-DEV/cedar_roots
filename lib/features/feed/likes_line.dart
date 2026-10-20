import '../../models/post.dart';

/// "Liked by you and 3 others", "Liked by Karim", "5 likes" ... or '' when nobody liked it.
String likesLine(Post post, int me) {
  final likes = post.likes;
  final liked = post.isLikedBy(me);
  final others = likes.length - (liked ? 1 : 0);

  String others_(int n) => '$n ${n == 1 ? 'other' : 'others'}';

  if (liked) {
    return others > 0 ? 'Liked by you and ${others_(others)}' : 'Liked by you';
  }
  if (likes.isEmpty) return '';
  final first = likes.first.liker?.name;
  if (first == null || first.isEmpty) {
    return '${likes.length} ${likes.length == 1 ? 'like' : 'likes'}';
  }
  final rest = likes.length - 1;
  return rest == 0 ? 'Liked by $first' : 'Liked by $first and ${others_(rest)}';
}
