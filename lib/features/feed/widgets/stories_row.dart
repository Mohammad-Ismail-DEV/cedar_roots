import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/story.dart';
import '../../../models/user.dart';
import '../../../shared/widgets/ring_avatar.dart';

/// The horizontally scrolling row of stories: "Your story" first, then connections.
/// A gradient ring means there is something you have not watched yet.
class StoriesRow extends StatelessWidget {
  const StoriesRow({
    super.key,
    required this.me,
    required this.groups,
    required this.myUserId,
    required this.onCreate,
    required this.onOpen,
  });

  final User? me;
  final List<StoryGroup> groups;
  final int myUserId;

  /// Opens the "new story" screen.
  final VoidCallback onCreate;

  /// Opens the viewer on `groups[index]`.
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final myIndex = groups.indexWhere((g) => g.user.id == myUserId);
    final hasMine = myIndex >= 0;

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
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          SizedBox(
            width: 68,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: hasMine ? () => onOpen(myIndex) : onCreate,
                      child: RingAvatar(
                        name: me?.name ?? '?',
                        imageUrl: me?.profilePic,
                        blob: me?.profilePicBlob,
                        radius: 30,
                        ringed: hasMine && !groups[myIndex].allSeen,
                        dimRing: hasMine && groups[myIndex].allSeen,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Semantics(
                        button: true,
                        label: 'Add to your story',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onCreate,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                label('Your story', dim: !hasMine),
              ],
            ),
          ),
          for (var i = 0; i < groups.length; i++)
            if (i != myIndex)
              InkWell(
                onTap: () => onOpen(i),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      RingAvatar(
                        name: groups[i].user.name,
                        imageUrl: groups[i].user.profilePic,
                        blob: groups[i].user.profilePicBlob,
                        radius: 30,
                        ringed: !groups[i].allSeen,
                        dimRing: groups[i].allSeen,
                      ),
                      const SizedBox(height: 4),
                      label(
                        groups[i].user.name.split(' ').first,
                        dim: groups[i].allSeen,
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
