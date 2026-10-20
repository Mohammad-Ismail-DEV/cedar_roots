import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/image_url.dart';
import '../../core/time_label.dart';
import '../../shared/widgets/post_media.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'stories.dart';

/// Full-screen view of someone's newest post. Advances on its own after a few seconds,
/// tap the right or left side to skip, hold to pause.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
  });

  final List<StoryEntry> entries;
  final int initialIndex;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 5);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _duration,
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) _next();
  });

  late int _index = widget.initialIndex;

  StoryEntry get _entry => widget.entries[_index];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _start() {
    // Provider state may not change while the widget tree is building.
    Future.microtask(() {
      if (mounted) {
        ref.read(seenStoriesProvider.notifier).mark(_entry.latest.id);
      }
    });
    _progress.forward(from: 0);
  }

  void _next() {
    if (_index >= widget.entries.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index++);
    _start();
  }

  void _previous() {
    if (_index == 0) {
      _progress.forward(from: 0);
      return;
    }
    setState(() => _index--);
    _start();
  }

  void _message() {
    final author = _entry.author;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(AppRoutes.chat(userId: author.id, name: author.name));
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final post = entry.latest;
    final hasPhoto = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        onTapUp: (details) {
          if (details.localPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              Center(
                child: CachedNetworkImage(
                  httpHeaders: imageHeaders,
                  imageUrl: sizedImageUrl(
                    post.imageUrl!,
                    logicalWidth: width,
                    pixelRatio: pixelRatio,
                  ),
                  fit: BoxFit.contain,
                  placeholder:
                      (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  errorWidget:
                      (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: textGradientFor(post.userId),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      post.content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder:
                          (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              minHeight: 3,
                              backgroundColor: Colors.white30,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: entry.author.name,
                          imageUrl: entry.author.profilePic,
                          blob: entry.author.profilePicBlob,
                          radius: 16,
                          backgroundColor: Colors.white24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: entry.author.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '  ${shortAgo(post.createdAt)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [Shadow(blurRadius: 6)],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (hasPhoto && post.content.isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: Colors.black38,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _message,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: const StadiumBorder(),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Send message'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
