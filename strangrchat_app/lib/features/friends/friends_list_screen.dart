import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/sticker_avatar.dart';
import '../../app/tokens.dart';
import 'friends_provider.dart';

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(friendsProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _FriendsError(onRetry: () => ref.invalidate(friendsProvider)),
      data: (data) {
        if (data.friends.isEmpty && data.incomingRequests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StickerAvatar(variant: 2, size: 112),
                  const SizedBox(height: AppTokens.space20),
                  Text(
                    'Your people will be here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    data.outgoingRequests.isEmpty
                        ? 'Connect with someone during a chat to start a friendship.'
                        : 'Your friend request is waiting for a reply.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(friendsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (data.incomingRequests.isNotEmpty) ...[
                Text(
                  'Friend requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final request in data.incomingRequests)
                  _RequestRow(
                    request: request,
                    onAction: (accept) =>
                        _respond(context, ref, request, accept: accept),
                  ),
                const SizedBox(height: 20),
              ],
              if (data.friends.isNotEmpty) ...[
                Text(
                  'Your friends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final friend in data.friends)
                  Card(
                    child: ListTile(
                      leading: const StickerAvatar(variant: 1, size: 48),
                      title: Text(friend.name),
                      subtitle: const Text('Friend connection'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        '/friends/${Uri.encodeComponent(friend.id)}',
                        extra: friend.name,
                      ),
                    ),
                  ),
              ],
              if (data.outgoingRequests.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Sent requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final request in data.outgoingRequests)
                  Card(
                    child: ListTile(
                      leading: const StickerAvatar(variant: 3, size: 48),
                      title: Text(request.name),
                      subtitle: const Text('Waiting for a reply'),
                      trailing: const Icon(Icons.hourglass_top_rounded),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    FriendRequestSummary request, {
    required bool accept,
  }) async {
    try {
      final service = ref.read(friendServiceProvider);
      if (accept) {
        await service.acceptRequest(request.requestId);
      } else {
        await service.rejectRequest(request.requestId);
      }
      ref.invalidate(friendsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update that request. Try again.'),
          ),
        );
      }
    }
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onAction});

  final FriendRequestSummary request;
  final ValueChanged<bool> onAction;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const StickerAvatar(variant: 0, size: 48),
            title: Text(request.name),
            subtitle: const Text('Wants to keep chatting'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => onAction(false),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => onAction(true),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FriendsError extends StatelessWidget {
  const _FriendsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTokens.muted, size: 40),
          const SizedBox(height: 12),
          Text(
            'Friends could not load',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
