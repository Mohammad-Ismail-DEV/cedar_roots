import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ui.dart';
import '../../data/media_repository.dart';
import '../../data/post_repository.dart';
import '../../models/post.dart';
import '../feed/feed_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.existingPost});

  /// Set when editing.
  final Post? existingPost;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late final _content = TextEditingController(
    text: widget.existingPost?.content ?? '',
  );
  File? _newImage;
  String? _existingImageUrl;
  bool _submitting = false;

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.existingPost?.imageUrl;
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  /// Takes the photo exactly as it is: no cropping, no resizing, no recompression.
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _newImage = File(picked.path);
      _existingImageUrl = null;
    });
  }

  Future<void> _submit() async {
    final content = _content.text.trim();
    if (content.isEmpty && _newImage == null && _existingImageUrl == null) {
      return showSnack(context, 'Please add text or an image');
    }

    setState(() => _submitting = true);
    try {
      var imageUrl = _existingImageUrl;
      if (_newImage != null) {
        imageUrl = await ref
            .read(mediaRepositoryProvider)
            .uploadImage(XFile(_newImage!.path));
      }

      final posts = ref.read(postRepositoryProvider);
      if (_isEditing) {
        await posts.update(
          widget.existingPost!.id,
          content: content,
          imageUrl: imageUrl,
        );
      } else {
        await posts.create(content: content, imageUrl: imageUrl);
      }

      await ref.read(feedProvider.notifier).refresh();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Post' : 'Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _content,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Previews keep the photo's own shape; nothing is cropped.
                    if (_newImage != null)
                      _Preview(
                        image: Image.file(
                          _newImage!,
                          fit: BoxFit.contain,
                          cacheWidth: 1080,
                        ),
                        onRemove: () => setState(() => _newImage = null),
                      )
                    else if (_existingImageUrl != null)
                      _Preview(
                        image: Image.network(
                          _existingImageUrl!,
                          fit: BoxFit.contain,
                          cacheWidth: 1080,
                        ),
                        onRemove:
                            () => setState(() => _existingImageUrl = null),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Add Image'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
              ),
              child:
                  _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Update Post' : 'Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: SizedBox(width: double.infinity, child: image),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
