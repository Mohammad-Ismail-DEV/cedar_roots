import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/ui.dart';
import '../connections/connections_screen.dart';
import 'chat_screen.dart';
import 'conversations_provider.dart';
import 'widgets/chat_list_tile.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final me = ref.watch(currentUserIdProvider) ?? 0;
    final notifier = ref.read(conversationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Stack(
        children: [
          conversations.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage(error)),
                      TextButton(
                        onPressed: notifier.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
            data:
                (list) =>
                    list.isEmpty
                        ? const Center(
                          child: Text(
                            'No open chats',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: notifier.refresh,
                          child: ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final conversation = list[index];
                              return ChatListTile(
                                conversation: conversation,
                                myUserId: me,
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChatScreen(
                                              receiverId: conversation.userId,
                                              name: conversation.name,
                                            ),
                                      ),
                                    ).then((_) => notifier.refresh()),
                              );
                            },
                          ),
                        ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton(
                backgroundColor: const Color(
                  0xFF228B22,
                ).withValues(alpha: 0.85),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectionsScreen(),
                      ),
                    ),
                child: const Icon(Icons.chat, size: 30, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
