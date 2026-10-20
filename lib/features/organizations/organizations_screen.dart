import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'organization_providers.dart';
import '../../core/theme.dart';

/// The organizations a user belongs to, with a button to create a new one.
class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key, this.userId});

  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    if (me == null) {
      return const SignInRequired(title: 'My Organizations');
    }
    final target = userId ?? me;
    final organizations = ref.watch(myOrganizationsProvider(target));

    return Scaffold(
      appBar: AppBar(title: const Text('My Organizations')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ShadowButton(
            label: 'Create Organization',
            onTap: () async {
              await Navigator.push(context, AppRoutes.organizationForm());
              ref.invalidate(myOrganizationsProvider(target));
            },
          ),
        ),
      ),
      body: organizations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(myOrganizationsProvider(target)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No Organizations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You haven't created or joined any organizations yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.palette.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final org = list[index];
              return ListTile(
                minTileHeight: 64,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: UserAvatar(
                  name: org.name,
                  imageUrl: org.logo,
                  blob: org.logoBlob,
                  radius: 24,
                  backgroundColor: context.palette.avatarBg,
                ),
                title: Text(
                  org.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: context.palette.muted,
                ),
                onTap: () async {
                  await Navigator.push(context, AppRoutes.organization(org.id));
                  ref.invalidate(myOrganizationsProvider(target));
                },
              );
            },
          );
        },
      ),
    );
  }
}
