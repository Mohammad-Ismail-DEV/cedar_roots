import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../data/auth_repository.dart';

/// Change your password: enter the current one, then the new one twice.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _visible = false;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// A message when the form is not ready to send, or null when it is.
  String? get _problem {
    if (_current.text.isEmpty) return 'Enter your current password';
    if (_next.text.length < 6) {
      return 'The new password needs at least 6 characters';
    }
    if (_next.text != _confirm.text) return 'The new passwords do not match';
    return null;
  }

  Future<void> _save() async {
    final problem = _problem;
    if (problem != null) {
      showSnack(context, problem);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Password updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputAction action = TextInputAction.next,
    bool toggle = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: !_visible,
      textInputAction: action,
      onSubmitted: action == TextInputAction.done ? (_) => _save() : null,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon:
            toggle
                ? IconButton(
                  tooltip: _visible ? 'Hide passwords' : 'Show passwords',
                  icon: Icon(
                    _visible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                )
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_current, 'Current password', toggle: true),
          const SizedBox(height: 12),
          _field(_next, 'New password'),
          const SizedBox(height: 12),
          _field(
            _confirm,
            'Confirm new password',
            action: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Update password'),
          ),
        ],
      ),
    );
  }
}
