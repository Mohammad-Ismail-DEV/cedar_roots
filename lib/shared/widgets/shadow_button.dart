import 'package:flutter/material.dart';

/// White rounded button with a soft shadow (replaces five hand-copied versions).
class ShadowButton extends StatelessWidget {
  const ShadowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.green,
    this.icon,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: fontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
