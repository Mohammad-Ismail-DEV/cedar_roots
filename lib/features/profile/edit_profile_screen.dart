import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../data/user_repository.dart';
import '../../shared/widgets/user_avatar.dart';
import 'profile_actions.dart';
import 'profile_provider.dart';

/// Change your name, bio, location and profile photo.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _location = TextEditingController();
  bool _filled = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  /// Fills the fields once, from the profile that is already on screen or arrives first.
  void _prefill(ProfileData data) {
    if (_filled) return;
    _filled = true;
    _name.text = data.user.name;
    _bio.text = data.user.bio ?? '';
    _location.text = data.user.location ?? '';
  }

  Future<void> _save(int me) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .update(
            me,
            name: name,
            bio: _bio.text.trim(),
            location: _location.text.trim(),
          );
      ref.invalidate(profileProvider(me));
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Profile updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) return const Scaffold();
    final profile = ref.watch(profileProvider(me));
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(me),
            child: Text(_saving ? 'Saving…' : 'Done'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (data) {
          _prefill(data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Center(
                child: UserAvatar(
                  name: data.user.name,
                  imageUrl: data.user.profilePic,
                  blob: data.user.profilePicBlob,
                  radius: 46,
                  backgroundColor: palette.avatarBg,
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => changeProfilePicture(context, ref, me),
                  child: const Text('Change profile photo'),
                ),
              ),
              const SizedBox(height: 8),
              _label('Name', palette),
              TextField(
                controller: _name,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 12),
              _label('Bio', palette),
              TextField(
                controller: _bio,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 12),
              _label('Location', palette),
              TextField(
                controller: _location,
                maxLength: 255,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 12),
              Text(
                'Your email and password are managed in account settings.',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text, AppPalette palette) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(color: palette.muted, fontSize: 13)),
  );
}
