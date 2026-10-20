import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../data/auth_repository.dart';

/// Change your email in two steps: enter the new address and your password, then type the
/// 4-digit code we send to that new address.
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _code = '';
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailLooksValid {
    final value = _email.text.trim();
    return value.contains('@') && value.contains('.') && value.length >= 5;
  }

  Future<void> _sendCode() async {
    if (!_emailLooksValid) {
      showSnack(context, 'Enter a valid email address');
      return;
    }
    if (_password.text.isEmpty) {
      showSnack(context, 'Enter your password to confirm it is you');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .startEmailChange(
            newEmail: _email.text.trim().toLowerCase(),
            password: _password.text,
          );
      if (mounted) setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_code.length != 4) {
      showSnack(context, 'Please enter the 4-digit code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final email = await ref
          .read(authRepositoryProvider)
          .confirmEmailChange(_code);
      await ref.read(sessionProvider.notifier).updateProfile(email: email);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Email updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _button(String label, VoidCallback onTap) => ElevatedButton(
    onPressed: _busy ? null : onTap,
    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
    child:
        _busy
            ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
            : Text(label),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Change email')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children:
            _codeSent
                ? [
                  Text(
                    'Enter the 4-digit code sent to ${_email.text.trim()}.',
                    style: TextStyle(color: palette.muted),
                  ),
                  const SizedBox(height: 20),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 54,
                      fieldWidth: 54,
                      activeColor: scheme.onSurface,
                      inactiveColor: palette.border,
                      selectedColor: scheme.primary,
                      activeFillColor: Colors.transparent,
                      inactiveFillColor: Colors.transparent,
                      selectedFillColor: Colors.transparent,
                    ),
                    onChanged: (value) => setState(() => _code = value),
                  ),
                  const SizedBox(height: 16),
                  _button('Confirm new email', _confirm),
                  TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('Send a new code'),
                  ),
                ]
                : [
                  Text(
                    'We will send a code to the new address to confirm it.',
                    style: TextStyle(color: palette.muted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'New email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendCode(),
                    decoration: const InputDecoration(
                      hintText: 'Your password',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _button('Send code', _sendCode),
                ],
      ),
    );
  }
}
