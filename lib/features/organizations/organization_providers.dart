import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/organization_repository.dart';
import '../../models/organization.dart';

/// Organizations a user belongs to (any role).
final myOrganizationsProvider = FutureProvider.autoDispose.family<
  List<Organization>,
  int
>((ref, userId) => ref.watch(organizationRepositoryProvider).forUser(userId));

/// One organization with its members, followers and events.
final organizationProvider = AsyncNotifierProvider.autoDispose
    .family<OrganizationNotifier, Organization, int>(OrganizationNotifier.new);

class OrganizationNotifier
    extends AutoDisposeFamilyAsyncNotifier<Organization, int> {
  OrganizationRepository get _repo => ref.read(organizationRepositoryProvider);

  @override
  Future<Organization> build(int arg) => _repo.getById(arg);

  Future<void> reload() async {
    state = AsyncData(await _repo.getById(arg));
  }

  Future<void> toggleFollow() async {
    final me = ref.read(currentUserIdProvider);
    final current = state.valueOrNull;
    if (me == null || current == null) return;

    if (current.isFollowedBy(me)) {
      await _repo.unfollow(arg);
    } else {
      await _repo.follow(arg);
    }
    await reload();
  }

  Future<void> delete() => _repo.delete(arg);
}

/// Members of an organization and the actions the owner can take on them.
final organizationMembersProvider = AsyncNotifierProvider.autoDispose
    .family<OrganizationMembersNotifier, List<OrgMember>, int>(
      OrganizationMembersNotifier.new,
    );

class OrganizationMembersNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<OrgMember>, int> {
  OrganizationRepository get _repo => ref.read(organizationRepositoryProvider);

  @override
  Future<List<OrgMember>> build(int arg) => _repo.members(arg);

  Future<void> _reload() async {
    state = AsyncData(await _repo.members(arg));
  }

  Future<void> add(int userId, OrgRole role) async {
    await _repo.addMember(userId: userId, organizationId: arg, role: role);
    await _reload();
  }

  Future<void> changeRole(int userId, OrgRole role) async {
    await _repo.updateMemberRole(
      userId: userId,
      organizationId: arg,
      role: role,
    );
    await _reload();
  }

  Future<void> remove(int userId) async {
    await _repo.removeMember(userId: userId, organizationId: arg);
    await _reload();
  }
}
