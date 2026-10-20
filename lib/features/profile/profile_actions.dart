import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/photo_crop.dart';
import '../../core/ui.dart';
import 'profile_provider.dart';

/// Pick a photo, crop it, and set it as the signed-in user's profile picture.
Future<void> changeProfilePicture(
  BuildContext context,
  WidgetRef ref,
  int userId,
) async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  final cropped = await cropPhoto(picked.path);
  if (cropped == null || !context.mounted) return;

  try {
    await ref
        .read(profileProvider(userId).notifier)
        .changeProfilePicture(XFile(cropped.path));
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}
