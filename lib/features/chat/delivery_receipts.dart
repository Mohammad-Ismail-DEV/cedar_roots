import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_repository.dart';

/// Tells the sender "delivered" the moment any message reaches this device,
/// whichever screen is open. Watched once at the app root.
final deliveryReceiptsProvider = Provider<void>((ref) {
  final chat = ref.watch(chatRepositoryProvider);
  final subscription = chat.incoming.listen(
    (message) => chat.acknowledgeDelivery(message.id),
  );
  ref.onDispose(subscription.cancel);
});
