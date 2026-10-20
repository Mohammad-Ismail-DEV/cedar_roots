import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../models/json_helpers.dart';
import '../models/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepository(ref.watch(apiClientProvider)),
);

class OrganizationRepository {
  OrganizationRepository(this._api);

  final ApiClient _api;

  Future<List<Organization>> search(String query) async {
    final data = await _api.get('/organizations', query: {'search': query});
    return asMapList(data).map(Organization.fromJson).toList();
  }

  Future<List<Organization>> forUser(int userId) async {
    final data = await _api.get('/organizations/user/$userId');
    return asMapList(data).map(Organization.fromJson).toList();
  }

  Future<Organization> getById(int id) async =>
      Organization.fromJson(asMap(await _api.get('/organizations/$id'))!);

  Future<void> create({
    required String name,
    String? description,
    String? location,
    String? website,
    String? logo,
  }) => _api.post(
    '/organizations',
    body: {
      'name': name,
      'description': description,
      'location': location,
      'website': website,
      'logo': logo,
    },
  );

  Future<void> update(
    int id, {
    required String name,
    String? description,
    String? location,
    String? website,
    String? logo,
  }) => _api.put(
    '/organizations/$id',
    body: {
      'name': name,
      'description': description,
      'location': location,
      'website': website,
      'logo': logo,
    },
  );

  Future<void> delete(int id) => _api.delete('/organizations/$id');

  Future<void> follow(int organizationId) => _api.post(
    '/organization_followers',
    body: {'organization_id': organizationId},
  );

  Future<void> unfollow(int organizationId) => _api.delete(
    '/organization_followers',
    body: {'organization_id': organizationId},
  );

  Future<List<OrgMember>> members(int organizationId) async {
    final data = await _api.get('/organization_members/$organizationId');
    return asMapList(data).map(OrgMember.fromJson).toList();
  }

  Future<void> addMember({
    required int userId,
    required int organizationId,
    OrgRole role = OrgRole.member,
  }) => _api.post(
    '/organization_members',
    body: {
      'user_id': userId,
      'organization_id': organizationId,
      'role': role.name,
    },
  );

  Future<void> updateMemberRole({
    required int userId,
    required int organizationId,
    required OrgRole role,
  }) => _api.put(
    '/organization_members/role',
    body: {
      'user_id': userId,
      'organization_id': organizationId,
      'role': role.name,
    },
  );

  Future<void> removeMember({
    required int userId,
    required int organizationId,
  }) => _api.delete(
    '/organization_members',
    body: {'user_id': userId, 'organization_id': organizationId},
  );
}
