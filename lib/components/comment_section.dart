import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentSection extends StatefulWidget {
  final int postId;
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _comments = [];
  int? _currentUserId;
  int? _postAuthorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('user_id');

    final res = await http.get(
      Uri.parse('http://13.50.2.82:3000/posts/${widget.postId}'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        _comments = data['Comments'] ?? [];
        _postAuthorId = data['user_id'];
        _isLoading = false;
      });

      // Scroll to bottom after short delay
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _submitComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getInt('user_id');
    if (_commentController.text.trim().isEmpty ||
        token == null ||
        userId == null)
      return;

    final res = await http.post(
      Uri.parse('http://13.50.2.82:3000/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _commentController.text.trim(),
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      await _fetchComments(); // Refresh comments
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final res = await http.delete(
      Uri.parse('http://13.50.2.82:3000/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      await _fetchComments(); // Refresh comments
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete comment')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder:
          (_, scrollSheetController) => SafeArea(
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
                      "Comments",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                controller: _scrollController,
                                itemCount: _comments.length,
                                itemBuilder: (ctx, i) {
                                  final comment = _comments[i];
                                  final user = comment['Author'];
                                  final avatarUrl = user?['profile_pic'];
                                  final name = user?['name'] ?? 'User';
                                  final time =
                                      comment['created_at']
                                          ?.substring(0, 16)
                                          .replaceAll('T', ' ') ??
                                      '';

                                  final isOwner =
                                      _currentUserId == user?['id'] ||
                                      _currentUserId == _postAuthorId;

                                  return ListTile(
                                    leading:
                                        avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                avatarUrl,
                                              ),
                                            )
                                            : CircleAvatar(
                                              backgroundColor: Colors.grey,
                                              child: Text(
                                                name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(comment['content'] ?? ''),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing:
                                        isOwner
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => _deleteComment(
                                                    comment['id'],
                                                  ),
                                            )
                                            : null,
                                    isThreeLine: true,
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: _submitComment,
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
