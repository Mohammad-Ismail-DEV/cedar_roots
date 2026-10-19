import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../models/json_helpers.dart';
import '../models/user.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(apiClientProvider)),
);

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  Future<List<User>> search(String query) async {
    final data = await _api.get('/users', query: {'search': query});
    return asMapList(data).map(User.fromJson).toList();
  }

  Future<User> getById(int id) async =>
      User.fromJson(asMap(await _api.get('/users/$id'))!);

  Future<void> update(
    int id, {
    String? name,
    String? profilePic,
    String? bio,
    String? location,
  }) => _api.put(
    '/users/$id',
    body: {
      if (name != null) 'name': name,
      if (profilePic != null) 'profile_pic': profilePic,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
    },
  );

  /// Uploads [file] and returns its public URL.
  Future<String> uploadImage(XFile file) => _api.uploadImage(file);
}
