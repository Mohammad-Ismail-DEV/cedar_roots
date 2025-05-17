import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? existingPost;
  const CreatePostScreen({Key? key, required this.userId, this.existingPost})
    : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ApiServices api = ApiServices();
  File? _selectedImage;
  bool _isSubmitting = false;
  String? _initialImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _contentController.text = widget.existingPost!['content'] ?? '';
      _initialImageUrl = widget.existingPost!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _initialImageUrl = null;
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null && _initialImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add text or an image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = _initialImageUrl;

      if (_selectedImage != null) {
        final uploaded = await api.uploadFile(XFile(_selectedImage!.path));
        imageUrl = uploaded;
      }

      final response =
          widget.existingPost != null
              ? await api.updatePost(widget.existingPost!['id'], {
                'content': content,
                'image_url': imageUrl,
              })
              : await api.createPost(content: content, imageUrl: imageUrl);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context); // Success
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to submit post')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost != null ? 'Edit Post' : 'Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Stack(
                children: [
                  Image.file(_selectedImage!, height: 150),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              )
            else if (_initialImageUrl != null)
              Stack(
                children: [
                  Image.network(_initialImageUrl!, height: 150),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _initialImageUrl = null),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Add Image'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        widget.existingPost != null ? 'Update Post' : 'Post',
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
