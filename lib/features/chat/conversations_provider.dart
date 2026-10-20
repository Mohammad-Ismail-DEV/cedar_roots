import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../data/chat_repository.dart';
import '../../models/message.dart';

/// The chat list: shows the last known list instantly, then keeps itself fresh.
final conversationsProvider = AsyncNotifierProvider.autoDispose<
  ConversationsNotifier,
  List<Conversation>
>(ConversationsNotifier.new);

class ConversationsNotifier
    extends AutoDisposeAsyncNotifier<List<Conversation>> {
  bool _refreshing = false;

  @override
  Future<List<Conversation>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    final chat = ref.read(chatRepositoryProvider);

    final subscriptions = <StreamSubscription<dynamic>>[
      chat.incoming.listen((_) => refresh()),
      chat.saved.listen((_) => refresh()),
      chat.seen.listen((_) => refresh()),
      chat.connection.where((connected) => connected).listen((_) => refresh()),
    ];
    ref.onDispose(() {
      for (final s in subscriptions) {
        s.cancel();
      }
    });

    final cached = chat.cachedConversations();
    if (cached != null) {
      Future.microtask(refresh);
      return cached;
    }
    return chat.fetchConversations();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      state = AsyncData(
        await ref.read(chatRepositoryProvider).fetchConversations(),
      );
    } catch (e, stack) {
      if (!state.hasValue) state = AsyncError(e, stack);
    } finally {
      _refreshing = false;
    }
  }
}
