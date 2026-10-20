import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../models/json_helpers.dart';
import '../models/story.dart';

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(ref.watch(apiClientProvider)),
);

class StoryRepository {
  StoryRepository(this._api);

  final ApiClient _api;

  /// Active stories from me and my connections, mine first.
  Future<List<StoryGroup>> feed() async {
    final data = await _api.get('/stories');
    return asMapList(data).map(StoryGroup.fromJson).toList();
  }

  Future<Story> createPhoto(String imageUrl) async => Story.fromJson(
    asMap(
      await _api.post(
        '/stories',
        body: {'type': 'image', 'image_url': imageUrl},
      ),
    )!,
  );

  Future<Story> createText(String text, {required int bg}) async =>
      Story.fromJson(
        asMap(
          await _api.post(
            '/stories',
            body: {'type': 'text', 'text': text, 'bg': bg},
          ),
        )!,
      );

  Future<void> markViewed(int storyId) => _api.post('/stories/$storyId/view');

  Future<List<StoryViewer>> viewers(int storyId) async {
    final data = await _api.get('/stories/$storyId/viewers');
    return asMapList(data).map(StoryViewer.fromJson).toList();
  }

  Future<void> delete(int storyId) => _api.delete('/stories/$storyId');
}
