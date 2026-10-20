import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The app's standard button. Despite the name it no longer has a shadow: a primary
/// action is filled with the accent colour, and passing `Colors.red` makes it a
/// quiet destructive button.
class ShadowButton extends StatelessWidget {
  const ShadowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onTap;

  /// Only `Colors.red` changes the look (destructive); anything else is primary.
  final Color? color;
  final IconData? icon;
  final double fontSize;

  bool get _destructive => color == Colors.red;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final background = _destructive ? palette.inputBg : scheme.primary;
    final foreground = _destructive ? palette.danger : scheme.onPrimary;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foreground, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
