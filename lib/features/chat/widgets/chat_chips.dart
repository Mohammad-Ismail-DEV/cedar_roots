import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// "March 3, 2026" pill between messages of different days.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.formattedDate});

  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.palette.inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          formattedDate,
          style: TextStyle(color: context.palette.muted, fontSize: 12),
        ),
      ),
    );
  }
}

class NewMessageIndicator extends StatelessWidget {
  const NewMessageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'New Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({
    super.key,
    required this.newMessagesCount,
    required this.onPressed,
  });

  final int newMessagesCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 20,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          FloatingActionButton.small(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            onPressed: onPressed,
            child: const Icon(Icons.arrow_downward),
          ),
          if (newMessagesCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.palette.heart,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '$newMessagesCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
