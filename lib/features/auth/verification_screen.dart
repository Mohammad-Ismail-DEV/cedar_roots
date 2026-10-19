import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/api_client.dart';
import '../../core/ui.dart';
import '../../data/auth_repository.dart';
import '../shell/nav_bar.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Verify your account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 4-digit PIN code sent to your email ${widget.email}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 50,
                activeColor: Colors.black,
                inactiveColor: Colors.grey,
                selectedColor: Colors.blue,
              ),
              onChanged: (value) => setState(() => _code = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Verify',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: const Text(
                'Request new code',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
