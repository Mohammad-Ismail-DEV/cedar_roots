import 'package:flutter/material.dart';

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
  final VoidCallback onImagePick;
  final ValueChanged<String>? onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: isEnabled ? onImagePick : null,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEnabled,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: isEnabled ? onSend : null,
          ),
        ],
      ),
    );
  }
}
