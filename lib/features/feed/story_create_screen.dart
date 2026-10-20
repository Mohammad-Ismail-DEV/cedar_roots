import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photo_crop.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../data/media_repository.dart';
import '../../data/story_repository.dart';
import '../../shared/widgets/post_media.dart';
import 'stories.dart';

/// Add to your story: a photo (cropped, full resolution) or a text card on a gradient.
/// It stays up for 24 hours.
class StoryCreateScreen extends ConsumerStatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  ConsumerState<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends ConsumerState<StoryCreateScreen> {
  static const _gradientCount = 7;

  bool _photoMode = true;
  XFile? _photo;
  final _text = TextEditingController();
  int _bg = 0;
  bool _sharing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) return;

    var path = picked.path;
    // The crop screen is mobile only; the photo is kept whole on web.
    if (!kIsWeb) {
      final cropped = await cropPhoto(path);
      if (cropped == null || !mounted) return;
      path = cropped.path;
    }
    setState(() => _photo = XFile(path));
  }

  bool get _canShare =>
      !_sharing && (_photoMode ? _photo != null : _text.text.trim().isNotEmpty);

  Future<void> _share() async {
    if (!_canShare) return;
    setState(() => _sharing = true);
    try {
      final stories = ref.read(storyRepositoryProvider);
      if (_photoMode) {
        final url = await ref
            .read(mediaRepositoryProvider)
            .uploadImage(_photo!);
        await stories.createPhoto(url);
      } else {
        await stories.createText(_text.text.trim(), bg: _bg);
      }
      await ref.read(storiesProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Added to your story');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _modeButton(String label, bool photo) {
    final selected = _photoMode == photo;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _photoMode = photo),
        style: TextButton.styleFrom(
          backgroundColor:
              selected ? scheme.onSurface : context.palette.inputBg,
          foregroundColor: selected ? scheme.surface : scheme.onSurface,
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _photoBody() {
    final palette = context.palette;
    final photo = _photo;
    if (photo == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, size: 56, color: palette.muted),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose a photo'),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take a photo'),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black,
            child:
                kIsWeb
                    ? Image.network(photo.path, fit: BoxFit.contain)
                    : Image.file(File(photo.path), fit: BoxFit.contain),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            tooltip: 'Choose a different photo',
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            onPressed: () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _textBody() {
    return Container(
      decoration: BoxDecoration(gradient: textGradientFor(_bg)),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: TextField(
                  controller: _text,
                  maxLength: 280,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Type something...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: false,
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _gradientCount,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder:
                  (_, i) => Semantics(
                    button: true,
                    selected: i == _bg,
                    label: 'Background ${i + 1}',
                    child: GestureDetector(
                      onTap: () => setState(() => _bg = i),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: textGradientFor(i),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: i == _bg ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New story'),
        actions: [
          TextButton(
            onPressed: _canShare ? _share : null,
            child:
                _sharing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Share'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _modeButton('Photo', true),
                const SizedBox(width: 8),
                _modeButton('Text', false),
              ],
            ),
          ),
          Expanded(child: _photoMode ? _photoBody() : _textBody()),
        ],
      ),
    );
  }
}
