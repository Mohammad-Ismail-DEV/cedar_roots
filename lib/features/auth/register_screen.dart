import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/ui.dart';
import '../../data/auth_repository.dart';
import '../shell/nav_bar.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

final _emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
final _passwordPattern = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,16}$',
);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _passwordVisible = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final name = _name.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      return showSnack(context, 'Please fill in all the fields.');
    }
    if (!_emailPattern.hasMatch(email)) {
      return showSnack(context, 'Please enter a valid email address.');
    }
    if (!_passwordPattern.hasMatch(password)) {
      return showSnack(
        context,
        'Password must be 8-16 characters, include uppercase, lowercase, number, and symbol.',
      );
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signup(name: name, email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerificationScreen(email: email)),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const NavBar()),
                (_) => false,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _password,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed:
                      () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _register,
              child:
                  _busy
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
              child: const Text('Already have an account? Login here'),
            ),
          ],
        ),
      ),
    );
  }
}
