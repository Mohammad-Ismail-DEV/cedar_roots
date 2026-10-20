import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/theme_mode.dart';
import '../../core/ui.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
    );
    if (confirmed && context.mounted) await _signOut(context, ref);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final confirmed = await confirm(
      context,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(userRepositoryProvider).deleteAccount(userId);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
      return;
    }
    if (context.mounted) await _signOut(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final mode = ref.watch(themeModeProvider);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          heading('Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            minTileHeight: 52,
            onTap: () => _confirmSignOut(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.cancel_outlined, color: palette.danger),
            title: Text(
              'Delete Account',
              style: TextStyle(color: palette.danger),
            ),
            minTileHeight: 52,
            onTap: () => _deleteAccount(context, ref),
          ),
          heading('Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: Text(
              'Easier on the eyes at night',
              style: TextStyle(color: palette.muted),
            ),
            value: mode == ThemeMode.dark,
            onChanged:
                (on) => ref
                    .read(themeModeProvider.notifier)
                    .set(on ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      ),
    );
  }
}
