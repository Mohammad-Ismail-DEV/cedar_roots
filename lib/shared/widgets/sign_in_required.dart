import 'package:flutter/material.dart';

import '../../features/auth/login_screen.dart';

/// Shown instead of a screen that only makes sense for signed-in users.
class SignInRequired extends StatelessWidget {
  const SignInRequired({
    super.key,
    this.title,
    this.message = 'Please log in to continue.',
  });

  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
