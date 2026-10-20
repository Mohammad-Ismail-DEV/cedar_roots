import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/user.dart';
import '../../../shared/widgets/ring_avatar.dart';
import '../stories.dart';

/// The horizontally scrolling row of people with something new, with "Your story" first.
class StoriesRow extends StatelessWidget {
  const StoriesRow({
    super.key,
    required this.me,
    required this.entries,
    required this.onYourStory,
    required this.onOpen,
  });

  final User? me;
  final List<StoryEntry> entries;
  final VoidCallback onYourStory;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    Widget label(String text, {bool dim = false}) => SizedBox(
      width: 68,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: dim ? palette.muted : null),
      ),
    );

    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          InkWell(
            onTap: onYourStory,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RingAvatar(
                        name: me?.name ?? '?',
                        imageUrl: me?.profilePic,
                        blob: me?.profilePicBlob,
                        radius: 30,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  label('Your story', dim: true),
                ],
              ),
            ),
          ),
          for (var i = 0; i < entries.length; i++)
            InkWell(
              onTap: () => onOpen(i),
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 68,
                child: Column(
                  children: [
                    RingAvatar(
                      name: entries[i].author.name,
                      imageUrl: entries[i].author.profilePic,
                      blob: entries[i].author.profilePicBlob,
                      radius: 30,
                      ringed: !entries[i].seen,
                      dimRing: entries[i].seen,
                    ),
                    const SizedBox(height: 4),
                    label(
                      entries[i].author.name.split(' ').first,
                      dim: entries[i].seen,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
