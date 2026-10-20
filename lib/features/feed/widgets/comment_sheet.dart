import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../../profile/profile_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../post_details_provider.dart';
import 'comment_tile.dart';

/// Bottom sheet with a post's comments and a box to add one.
class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  PostDetailsNotifier get _notifier =>
      ref.read(postDetailsProvider(widget.postId).notifier);

  Future<void> _submit() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _notifier.addComment(content);
      _text.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(int commentId) async {
    final confirmed = await confirm(
      context,
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _notifier.deleteComment(commentId);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final post = ref.watch(postDetailsProvider(widget.postId));
    final me = ref.watch(currentUserIdProvider);
    final myUser =
        me == null ? null : ref.watch(profileProvider(me)).valueOrNull?.user;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder:
          (_, __) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Comments',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: post.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(errorMessage(e))),
                    data: (data) {
                      if (data.comments.isEmpty) {
                        return Center(
                          child: Text(
                            'No comments yet.\nStart the conversation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.muted),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: data.comments.length,
                        itemBuilder: (_, i) {
                          final comment = data.comments[i];
                          return CommentTile(
                            comment: comment,
                            onDelete:
                                canDeleteComment(
                                      post: data,
                                      comment: comment,
                                      me: me,
                                    )
                                    ? () => _delete(comment.id)
                                    : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 8),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: myUser?.name ?? '?',
                          imageUrl: myUser?.profilePic,
                          blob: myUser?.profilePicBlob,
                          radius: 16,
                          backgroundColor: palette.avatarBg,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(color: palette.muted),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        TextButton(
                          onPressed: _sending ? null : _submit,
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
