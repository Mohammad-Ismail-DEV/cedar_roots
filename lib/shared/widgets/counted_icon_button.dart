import 'package:flutter/material.dart';

/// An action icon with its count next to it (likes, comments). The count is hidden at zero.
class CountedIconButton extends StatelessWidget {
  const CountedIconButton({
    super.key,
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final int count;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
