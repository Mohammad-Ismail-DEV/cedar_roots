import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/providers.dart';

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(apiClientProvider)),
);

class MediaRepository {
  MediaRepository(this._api);

  final ApiClient _api;

  /// Uploads [file] and returns its public URL.
  Future<String> uploadImage(XFile file) => _api.uploadImage(file);
}
