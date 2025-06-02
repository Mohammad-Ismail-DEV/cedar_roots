import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailsScreen extends StatefulWidget {
  final int postId;
  final int userId;

  const PostDetailsScreen({
    Key? key,
    required this.postId,
    required this.userId,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  Map<String, dynamic>? post;
  bool isLiked = false;
  List<dynamic> comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final res = await http.get(
        Uri.parse('http://13.50.2.82:3000/posts/${widget.postId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final commentsRes = await http.get(
        Uri.parse('http://13.50.2.82:3000/comments/post/${widget.postId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200 && commentsRes.statusCode == 200) {
        final data = json.decode(res.body);
        final commentList = json.decode(commentsRes.body);

        if (!mounted) return;
        setState(() {
          post = data;
          comments = commentList;
          isLiked =
              data['Likes']?.any((l) => l['user_id'] == widget.userId) ?? false;
        });
      }
    } catch (e) {
      print('❌ Error fetching post details: $e');
    }
  }

  Future<void> _toggleLike() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final res = await http.post(
        Uri.parse('http://13.50.2.82:3000/posts/${widget.postId}/like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        _fetchPostDetails();
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final res = await http.post(
        Uri.parse('http://13.50.2.82:3000/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'post_id': widget.postId, 'content': content}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        _commentController.clear();
        _fetchPostDetails();
      }
    } catch (e) {
      print('❌ Error adding comment: $e');
    }
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    return dt != null ? DateFormat('yMMMd \u2022 h:mm a').format(dt) : raw;
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final author = post!['User'] ?? {};
    final name = author['name'] ?? 'User';
    final profilePic = author['profile_pic'];

    return Scaffold(
      appBar: AppBar(title: const Text("Post Details")),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: RefreshIndicator(
          onRefresh: _fetchPostDetails,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        profilePic != null ? NetworkImage(profilePic) : null,
                    child: profilePic == null ? Text(name[0]) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (post!['image_url'] != null &&
                  post!['image_url'].toString().isNotEmpty)
                Image.network(post!['image_url'], fit: BoxFit.cover),
              const SizedBox(height: 12),
              Text(post!['content'] ?? ''),
              const SizedBox(height: 8),
              Text(
                _formatDate(post!['created_at']),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                  Text('${post!['Likes']?.length ?? 0} likes'),
                ],
              ),
              const Divider(height: 32),
              const Text(
                "Comments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...comments.map((c) {
                final user = c['Author'] ?? {};
                final name = user['name'] ?? 'U';
                final profilePic = user['profile_pic'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        profilePic != null ? NetworkImage(profilePic) : null,
                    child: profilePic == null ? Text(name[0]) : null,
                  ),
                  title: Text(name),
                  subtitle: Text(c['content'] ?? ''),
                  trailing: Text(
                    _formatDate(c['created_at']),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
