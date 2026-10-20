import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Instagram-style message box: a rounded outline with the photo button inside and Send beside it.
class MessageInputField extends StatelessWidget {
  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onImagePick,
    this.onChanged,
    this.isEnabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onImagePick;
  final ValueChanged<String>? onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: isEnabled,
                        onChanged: onChanged,
                        onSubmitted: (_) => onSend(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: palette.muted),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send a photo',
                      icon: const Icon(Icons.image_outlined),
                      onPressed: isEnabled ? onImagePick : null,
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: isEnabled ? onSend : null,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
