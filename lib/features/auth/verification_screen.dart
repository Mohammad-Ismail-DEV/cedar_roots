import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/api_client.dart';
import '../../core/ui.dart';
import '../../data/auth_repository.dart';
import '../shell/nav_bar.dart';
import '../../core/theme.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  String _code = '';
  bool _busy = false;
  bool _resending = false;

  Future<void> _verify() async {
    if (_code.length != 4) {
      return showSnack(context, 'Please enter a valid 4-digit code.');
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verify(email: widget.email, code: _code);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NavBar()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendCode(widget.email);
      if (mounted) {
        showSnack(context, 'A new code has been sent to ${widget.email}.');
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Verify your email',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 4-digit PIN code sent to your email ${widget.email}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _verify,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
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
                      : const Text('Verify Email'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: const Text('Request new code'),
            ),
          ],
        ),
      ),
    );
  }
}
