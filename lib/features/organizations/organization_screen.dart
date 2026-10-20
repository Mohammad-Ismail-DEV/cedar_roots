import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../../models/event.dart';
import '../../models/organization.dart';
import '../../shared/widgets/shadow_button.dart';
import '../../shared/widgets/user_avatar.dart';
import '../shell/app_routes.dart';
import 'organization_providers.dart';

class OrganizationScreen extends ConsumerWidget {
  const OrganizationScreen({super.key, required this.organizationId});

  final int organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organization = ref.watch(organizationProvider(organizationId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Organization Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: organization.when(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final role = me == null ? null : org.roleOf(me);
    final following = me != null && org.isFollowedBy(me);
    final notifier = ref.read(organizationProvider(org.id).notifier);

    return RefreshIndicator(
      onRefresh: notifier.reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            UserAvatar(
              name: org.name,
              imageUrl: org.logo,
              radius: 50,
              backgroundColor: Colors.grey[400]!,
            ),
            const SizedBox(height: 16),
            Text(
              org.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              org.website ?? '',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _About(org: org, canManage: role == OrgRole.owner),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    Icons.people,
                    'Followers',
                    org.followers.length,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(Icons.event, 'Events', org.events.length),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (me == null)
              const Text('Login to follow this organization.')
            else if (role == null)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ShadowButton(
                  icon: following ? Icons.remove : Icons.add,
                  label:
                      following
                          ? 'Unfollow Organization'
                          : 'Follow Organization',
                  color: following ? Colors.red : Colors.green,
                  onTap: () => _run(context, notifier.toggleFollow),
                ),
              )
            else if (role.canManage)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ShadowButton(
                  icon: Icons.add,
                  label: 'Create Event',
                  onTap:
                      () => Navigator.push(
                        context,
                        AppRoutes.createEvent(org.id),
                      ).then((_) => notifier.reload()),
                ),
              ),
            const SizedBox(height: 24),
            if (org.events.isEmpty)
              const Text(
                'No events yet.',
                style: TextStyle(color: Colors.black54),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final event in org.events) _EventCard(event: event),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.org, required this.canManage});

  final Organization org;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'About',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (canManage)
                IconButton(
                  onPressed: () async {
                    final removed = await Navigator.push(
                      context,
                      AppRoutes.manageOrganization(org.id),
                    );
                    if (removed == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.settings, color: Colors.black54),
                  tooltip: 'Manage',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (org.description == null || org.description!.isEmpty)
                ? 'No description available.'
                : org.description!,
            style: const TextStyle(color: Colors.black87),
          ),
          if (org.location != null && org.location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    org.location!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 28),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, AppRoutes.event(event.id)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title.isEmpty ? 'Untitled Event' : event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (event.dateTime != null)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(event.dateTime!),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              (event.location == null || event.location!.isEmpty)
                  ? 'No location'
                  : event.location!,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
