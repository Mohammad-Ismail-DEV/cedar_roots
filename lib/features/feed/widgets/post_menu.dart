import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// The "..." sheet on a post: Edit and Delete for the owner, Go to post for everyone else.
Future<void> showPostMenu(
  BuildContext context, {
  required bool isMine,
  required VoidCallback onOpen,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  bool canOpen = true,
}) {
  final danger = context.palette.danger;

  Widget row(String label, VoidCallback action, {Color? color}) => ListTile(
    title: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontWeight: color == null ? FontWeight.w400 : FontWeight.w700,
      ),
    ),
    minTileHeight: 52,
    onTap: () {
      Navigator.pop(context);
      action();
    },
  );

  return showModalBottomSheet<void>(
    context: context,
    builder:
        (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine) ...[
                row('Edit', onEdit),
                row('Delete', onDelete, color: danger),
              ] else if (canOpen)
                row('Go to post', onOpen),
              row('Cancel', () {}),
            ],
          ),
        ),
  );
}
