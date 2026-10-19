import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session.dart';
import '../../../core/ui.dart';
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
    final post = ref.watch(postDetailsProvider(widget.postId));
    final me = ref.watch(currentUserIdProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder:
          (_, __) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: post.when(
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error: (e, _) => Center(child: Text(errorMessage(e))),
                        data: (data) {
                          if (data.comments.isEmpty) {
                            return const Center(child: Text('No comments yet'));
                          }
                          return ListView.builder(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: _sending ? null : _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
