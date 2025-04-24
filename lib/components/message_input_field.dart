import 'package:flutter/material.dart';

class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImagePick;
  final bool isEnabled;

  const MessageInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onImagePick,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.image), onPressed: onImagePick),
          Expanded(
            child: IgnorePointer(
              ignoring: !isEnabled,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: isEnabled ? onSend : null,
          ),
        ],
      ),
    );
  }
}
