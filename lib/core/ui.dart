import 'package:flutter/material.dart';

import 'api_client.dart';
import 'socket_client.dart';

/// Human-readable text for anything a repository can throw.
String errorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is SocketRequestException) return error.message;
  return 'Something went wrong. Please try again.';
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showErrorSnack(BuildContext context, Object error) =>
    showSnack(context, errorMessage(error));

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                confirmLabel,
                style: destructive ? const TextStyle(color: Colors.red) : null,
              ),
            ),
          ],
        ),
  );
  return result ?? false;
}
