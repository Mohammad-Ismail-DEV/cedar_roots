import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/image_url.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/time_label.dart';
import '../../core/ui.dart';
import '../../data/story_repository.dart';
import '../../models/story.dart';
import '../../shared/widgets/post_media.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'stories.dart';

/// Full-screen stories. Plays each person's stories in turn, five seconds each: tap the right
/// side to skip ahead, the left to go back, hold to pause, swipe down to close.
/// On your own story you can see who watched it and delete it.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroup,
  });

  final List<StoryGroup> groups;
  final int initialGroup;

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

  bool _loading = false;
  late int _group = widget.initialGroup;
  late int _index = widget.groups[widget.initialGroup].firstUnseenIndex;

  StoryGroup get _current => widget.groups[_group];
  Story get _story => _current.stories[_index];
  bool get _isMine => _current.user.id == ref.read(currentUserIdProvider);

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
    final userId = _current.user.id;
    final storyId = _story.id;
    // Provider state may not change while the widget tree is building.
    Future.microtask(() {
      if (mounted) {
        ref.read(storiesProvider.notifier).markViewed(userId, storyId);
      }
    });
    // A photo story only starts counting down once the photo is on screen.
    _loading = _story.isImage && _story.imageUrl != null;
    _progress.value = 0;
    if (!_loading) _progress.forward();
  }

  void _resume() {
    if (!_loading) _progress.forward();
  }

  void _imageReady(int storyId) {
    if (!_loading || storyId != _story.id) return;
    _loading = false;
    if (!_progress.isAnimating) _progress.forward();
  }

  void _close() => Navigator.of(context).maybePop();

  void _next() {
    if (_index < _current.stories.length - 1) {
      setState(() => _index++);
    } else if (_group < widget.groups.length - 1) {
      setState(() {
        _group++;
        _index = _current.firstUnseenIndex;
      });
    } else {
      _close();
      return;
    }
    _start();
  }

  void _previous() {
    if (_index > 0) {
      setState(() => _index--);
    } else if (_group > 0) {
      setState(() {
        _group--;
        _index = 0;
      });
    }
    _start();
  }

  void _message() {
    final user = _current.user;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(AppRoutes.chat(userId: user.id, name: user.name));
  }

  Future<void> _showViewers() async {
    _progress.stop();
    final story = _story;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ViewersSheet(storyId: story.id),
    );
    if (mounted) _resume();
  }

  Future<void> _delete() async {
    _progress.stop();
    final story = _story;
    final confirmed = await confirm(
      context,
      title: 'Delete story',
      message: 'This removes the story for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!mounted) return;
    if (!confirmed) {
      _resume();
      return;
    }
    try {
      await ref.read(storiesProvider.notifier).delete(story.id);
      if (mounted) _close();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
      _resume();
    }
  }

  Widget _content(Story story) {
    final width = MediaQuery.sizeOf(context).width;
    if (story.isImage && story.imageUrl != null) {
      return Center(
        child: CachedNetworkImage(
          key: ValueKey(story.id),
          httpHeaders: imageHeaders,
          imageUrl: sizedImageUrl(
            story.imageUrl!,
            logicalWidth: width,
            pixelRatio: MediaQuery.devicePixelRatioOf(context),
          ),
          fit: BoxFit.contain,
          imageBuilder: (_, image) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => mounted ? _imageReady(story.id) : null,
            );
            return Image(image: image, fit: BoxFit.contain);
          },
          placeholder:
              (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          errorWidget: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => mounted ? _imageReady(story.id) : null,
            );
            return const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 48,
            );
          },
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: textGradientFor(story.bg)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            story.text ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _current.user;
    final story = _story;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) _close();
        },
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
            _content(story),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder:
                          (_, __) => Row(
                            children: [
                              for (var i = 0; i < _current.stories.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value:
                                            i < _index
                                                ? 1
                                                : i == _index
                                                ? _progress.value
                                                : 0,
                                        minHeight: 3,
                                        backgroundColor: Colors.white30,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: user.name,
                          imageUrl: user.profilePic,
                          blob: user.profilePicBlob,
                          radius: 16,
                          backgroundColor: Colors.white24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _isMine ? 'Your story' : user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '  ${shortAgo(story.createdAt)}',
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
                        if (_isMine)
                          IconButton(
                            tooltip: 'Delete story',
                            color: Colors.white,
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        IconButton(
                          tooltip: 'Close',
                          color: Colors.white,
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (story.isImage && (story.text?.isNotEmpty ?? false))
                    Container(
                      width: double.infinity,
                      color: Colors.black38,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        story.text!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child:
                        _isMine
                            ? Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _showViewers,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.visibility_outlined),
                                label: Text(
                                  '${story.viewCount ?? 0} '
                                  '${story.viewCount == 1 ? 'viewer' : 'viewers'}',
                                ),
                              ),
                            )
                            : SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: _message,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: const StadiumBorder(),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
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

final _storyViewersProvider = FutureProvider.autoDispose
    .family<List<StoryViewer>, int>(
      (ref, storyId) => ref.read(storyRepositoryProvider).viewers(storyId),
    );

class _ViewersSheet extends ConsumerWidget {
  const _ViewersSheet({required this.storyId});

  final int storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final viewers = ref.watch(_storyViewersProvider(storyId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder:
          (_, controller) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Viewers',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const Divider(),
              Expanded(
                child: viewers.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(errorMessage(e))),
                  data:
                      (list) =>
                          list.isEmpty
                              ? Center(
                                child: Text(
                                  'No one has viewed this yet.',
                                  style: TextStyle(color: palette.muted),
                                ),
                              )
                              : ListView.builder(
                                controller: controller,
                                itemCount: list.length,
                                itemBuilder: (context, i) {
                                  final v = list[i];
                                  return ListTile(
                                    leading: UserAvatar(
                                      name: v.user.name,
                                      imageUrl: v.user.profilePic,
                                      blob: v.user.profilePicBlob,
                                      radius: 20,
                                      backgroundColor: palette.avatarBg,
                                    ),
                                    title: Text(v.user.name),
                                    trailing: Text(
                                      shortAgo(v.viewedAt),
                                      style: TextStyle(color: palette.muted),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        AppRoutes.profile(v.user.id),
                                      );
                                    },
                                  );
                                },
                              ),
                ),
              ),
            ],
          ),
    );
  }
}
