import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'user_avatar.dart';

/// An avatar with the gradient "something new" ring (or a quiet hairline when [ringed] is false).
class RingAvatar extends StatelessWidget {
  const RingAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.blob,
    this.radius = 18,
    this.ringed = false,
    this.dimRing = false,
  });

  final String name;
  final String? imageUrl;
  final String? blob;
  final double radius;
  final bool ringed;

  /// Show a thin grey ring (already seen) instead of the gradient.
  final bool dimRing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final avatar = UserAvatar(
      name: name,
      imageUrl: imageUrl,
      blob: blob,
      radius: radius,
      backgroundColor: palette.avatarBg,
    );

    if (!ringed && !dimRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: dimRing ? null : storyRingGradient,
        color: dimRing ? palette.border : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: avatar,
      ),
    );
  }
}
