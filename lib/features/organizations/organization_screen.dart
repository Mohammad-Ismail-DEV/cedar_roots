import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/event.dart';
import '../../models/organization.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/user_avatar.dart';
import '../events/event_style.dart';
import '../shell/app_routes.dart';
import 'organization_providers.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key, required this.organizationId});

  final int organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organization = ref.watch(organizationProvider(organizationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(organization.valueOrNull?.name ?? 'Organization'),
      ),
      body: organization.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(error)),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(
                          organizationProvider(organizationId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (org) => _Loaded(org: org),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.org});

  final Organization org;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final me = ref.watch(currentUserIdProvider);
    final role = me == null ? null : org.roleOf(me);
    final following = me != null && org.isFollowedBy(me);
    final notifier = ref.read(organizationProvider(org.id).notifier);

    return RefreshIndicator(
      onRefresh: notifier.reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 14, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                UserAvatar(
                  name: org.name,
                  imageUrl: org.logo,
                  blob: org.logoBlob,
                  radius: 40,
                  backgroundColor: palette.avatarBg,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${org.followers.length}', 'Followers'),
                      _stat('${org.events.length}', 'Events'),
                      _stat('${org.members.length}', 'Members'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (org.description != null && org.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      org.description!,
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                if (org.location != null && org.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      org.location!,
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ),
                if (org.website != null && org.website!.isNotEmpty)
                  Text(
                    org.website!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                if (me == null)
                  Expanded(
                    child: Text(
                      'Login to follow this organization.',
                      style: TextStyle(color: palette.muted),
                    ),
                  )
                else if (role == null)
                  Expanded(
                    child: ShadowButton(
                      label:
                          following
                              ? 'Unfollow Organization'
                              : 'Follow Organization',
                      color: following ? Colors.red : null,
                      onTap: () => _run(context, notifier.toggleFollow),
                    ),
                  )
                else ...[
                  if (role.canManage)
                    Expanded(
                      child: ShadowButton(
                        label: 'Create Event',
                        onTap:
                            () => Navigator.push(
                              context,
                              AppRoutes.createEvent(org.id),
                            ),
                      ),
                    ),
                  if (role == OrgRole.owner) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShadowButton(
                        label: 'Manage',
                        color: Colors.red,
                        icon: Icons.settings_outlined,
                        onTap: () async {
                          final removed = await Navigator.push(
                            context,
                            AppRoutes.manageOrganization(org.id),
                          );
                          if (removed == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Events',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (org.events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No events yet.',
                style: TextStyle(color: palette.muted),
              ),
            )
          else
            for (final event in org.events) _EventRow(event: event),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final date = event.dateTime;

    return InkWell(
      onTap: () => Navigator.push(context, AppRoutes.event(event.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: eventGradient(event.id),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  date == null
                      ? null
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('d').format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(date).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.isEmpty ? 'Untitled Event' : event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    [
                      if (date != null)
                        DateFormat('EEE, MMM d • h:mm a').format(date),
                      if (event.location != null && event.location!.isNotEmpty)
                        event.location!,
                    ].join(' · '),
                    style: TextStyle(color: palette.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
