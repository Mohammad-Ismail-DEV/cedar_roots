import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/deep_links.dart';
import '../../../core/session.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../../data/chat_repository.dart';
import '../../../models/post.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../chat/conversations_provider.dart';
import '../../connections/connections_provider.dart';

/// Share a post: send it to connections as a chat message, or share a link anywhere.
Future<void> showShareSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShareSheet(post: post),
  );
}

class ShareSheet extends ConsumerStatefulWidget {
  const ShareSheet({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  final _sent = <int>{};
  final _sending = <int>{};

  Future<void> _send(int userId) async {
    if (_sending.contains(userId) || _sent.contains(userId)) return;
    setState(() => _sending.add(userId));
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendPost(receiverId: userId, postId: widget.post.id);
      if (!mounted) return;
      setState(() => _sent.add(userId));
      // Show the new message in the Messages list without waiting for a refresh.
      ref.read(conversationsProvider.notifier).refresh().catchError((_) {});
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending.remove(userId));
    }
  }

  Future<void> _shareLink() async {
    final author = widget.post.author?.name;
    await Share.share(
      '${author == null ? 'A post' : 'A post by $author'} on Cedar Roots: '
      '${postLink(widget.post.id)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final me = ref.watch(currentUserIdProvider);
    final connections =
        me == null ? null : ref.watch(connectionsProvider(me)).valueOrNull;
    final people = [
      for (final c in connections?.accepted ?? const [])
        if (c.other(me!) case final user?) user,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder:
          (_, controller) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Share',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: palette.inputBg,
                  child: Icon(
                    Icons.ios_share,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                title: const Text('Share link...'),
                subtitle: Text(
                  'Opens in the app for people who have it',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
                onTap: _shareLink,
              ),
              const Divider(),
              Expanded(
                child:
                    connections == null
                        ? const Center(child: CircularProgressIndicator())
                        : people.isEmpty
                        ? Center(
                          child: Text(
                            'Connect with people to send them posts.',
                            style: TextStyle(color: palette.muted),
                          ),
                        )
                        : ListView.builder(
                          controller: controller,
                          itemCount: people.length,
                          itemBuilder: (context, i) {
                            final user = people[i];
                            final sent = _sent.contains(user.id);
                            final sending = _sending.contains(user.id);
                            return ListTile(
                              leading: UserAvatar(
                                name: user.name,
                                imageUrl: user.profilePic,
                                blob: user.profilePicBlob,
                                radius: 20,
                                backgroundColor: palette.avatarBg,
                              ),
                              title: Text(user.name),
                              trailing: SizedBox(
                                width: 84,
                                height: 36,
                                child: FilledButton(
                                  onPressed:
                                      sent || sending
                                          ? null
                                          : () => _send(user.id),
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor:
                                        sent ? palette.inputBg : null,
                                    disabledBackgroundColor:
                                        sent ? palette.inputBg : null,
                                    disabledForegroundColor:
                                        sent ? palette.muted : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      sending
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Text(sent ? 'Sent' : 'Send'),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
    );
  }
}
