import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/connection_repository.dart';
import '../../data/user_repository.dart';
import '../../models/connection.dart';
import '../../models/user.dart';

/// Connections, incoming requests and outgoing requests of one user (the argument).
/// Shows the last known lists immediately, then refreshes.
final connectionsProvider = AsyncNotifierProvider.autoDispose
    .family<ConnectionsNotifier, UserConnections, int>(ConnectionsNotifier.new);

class ConnectionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserConnections, int> {
  ConnectionRepository get _repo => ref.read(connectionRepositoryProvider);

  @override
  Future<UserConnections> build(int arg) async {
    final cached = _repo.cachedFor(arg);
    if (cached != null) {
      unawaited(refresh().catchError((_) {}));
      return cached;
    }
    return _repo.fetchFor(arg);
  }

  /// Throws on failure so pull-to-refresh can report it; old data stays visible.
  Future<void> refresh() async {
    state = AsyncData(await _repo.fetchFor(arg));
  }

  Future<void> respond(int connectionId, {required bool accept}) async {
    await _repo.respond(connectionId, accept: accept);
    await refresh();
  }
}

/// People matching a name, for the "Suggestions" lists.
final userSuggestionsProvider = FutureProvider.autoDispose
    .family<List<User>, String>(
      (ref, query) => ref.watch(userRepositoryProvider).search(query),
    );
