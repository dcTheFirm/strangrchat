import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'friends_provider.dart';

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, Friend friend) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove friend?'),
        content: Text('Remove ${friend.name} from your friends list?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (shouldRemove == true && context.mounted) {
      ref.read(friendsProvider.notifier).removeFriend(friend.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend.name} was removed from your friends.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    if (friends.isEmpty) return const _EmptyFriends();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
          child: Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.softBlush,
                child: Text(friend.name.replaceFirst('Stranger #', '#'), style: const TextStyle(color: AppTheme.primaryCoral, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(friend.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('Connected ${_connectedLabel(friend.connectedAt)}', style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => context.push('/chat'), icon: const Icon(Icons.chat_bubble_outline_rounded), label: const Text('Chat Now'))),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _confirmRemove(context, ref, friend),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.secondaryText, side: const BorderSide(color: AppTheme.border)),
                child: const Text('Remove'),
              ),
            ]),
          ]),
        );
      },
    );
  }

  static String _connectedLabel(DateTime connectedAt) {
    final elapsed = DateTime.now().difference(connectedAt);
    if (elapsed.inDays >= 1) return '${elapsed.inDays}d ago';
    if (elapsed.inHours >= 1) return '${elapsed.inHours}h ago';
    return 'just now';
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: AppTheme.softBlush, shape: BoxShape.circle), child: const Icon(Icons.people_outline_rounded, size: 42, color: AppTheme.primaryCoral)),
            const SizedBox(height: 18),
            const Text('No friends yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('When someone accepts your friend request, they will appear here.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.secondaryText)),
          ]),
        ),
      );
}
