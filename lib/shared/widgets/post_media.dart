import 'package:flutter/material.dart';

import '../../models/post.dart';
import 'post_image.dart';

const _textGradients = [
  [Color(0xFFF9CE34), Color(0xFFEE2A7B)],
  [Color(0xFF6228D7), Color(0xFFEE2A7B)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  [Color(0xFFF2994A), Color(0xFFF2C94C)],
  [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  [Color(0xFF2193B0), Color(0xFF6DD5ED)],
];

LinearGradient textGradientFor(int userId) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: _textGradients[userId.abs() % _textGradients.length],
);

/// A gradient square carrying the post's words, used when a post has no photo.
class TextPostCard extends StatelessWidget {
  const TextPostCard({super.key, required this.userId, required this.text});

  final int userId;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: textGradientFor(userId)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 9,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Short words fit nicely on a gradient square; anything longer would be cut off, so it is shown
/// as normal text instead.
bool isLongPostText(String text) =>
    text.trim().length > 150 || '\n'.allMatches(text.trim()).length >= 4;

/// A text-only post too long for the gradient square: just its words, in full.
class LongTextPost extends StatelessWidget {
  const LongTextPost({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 16, height: 1.4),
      ),
    );
  }
}

/// What a post shows edge to edge: its photo at its own shape, or its text on a gradient.
class PostMedia extends StatelessWidget {
  const PostMedia({super.key, required this.post, this.onPhotoTap});

  final Post post;
  final VoidCallback? onPhotoTap;

  bool get hasPhoto => post.imageUrl != null && post.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasPhoto) {
      return PostImage(url: post.imageUrl!, onTap: onPhotoTap, borderRadius: 0);
    }
    if (isLongPostText(post.content)) return LongTextPost(text: post.content);
    return TextPostCard(userId: post.userId, text: post.content);
  }
}
