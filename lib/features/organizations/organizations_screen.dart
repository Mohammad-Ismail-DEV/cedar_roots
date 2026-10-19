import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/sign_in_required.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'organization_providers.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Organizations',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Organizations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You haven't created or joined any organizations yet.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final org = list[index];
              return InkWell(
                onTap: () async {
                  await Navigator.push(context, AppRoutes.organization(org.id));
                  ref.invalidate(myOrganizationsProvider(target));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: org.name,
                        imageUrl: org.logo,
                        radius: 26,
                        backgroundColor: Colors.grey[400]!,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          org.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black45),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
