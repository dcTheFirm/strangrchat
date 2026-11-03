import 'package:flutter_riverpod/flutter_riverpod.dart';

class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final DateTime connectedAt;

  Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.connectedAt,
  });
}

class FriendsNotifier extends Notifier<List<Friend>> {
  @override
  List<Friend> build() => [
        Friend(
          id: '1',
          name: 'Stranger #4892',
          avatarUrl: 'https://picsum.photos/200',
          connectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Friend(
          id: '2',
          name: 'Stranger #1024',
          avatarUrl: 'https://picsum.photos/201',
          connectedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  void removeFriend(String id) {
    state = state.where((f) => f.id != id).toList();
  }
}

final friendsProvider = NotifierProvider<FriendsNotifier, List<Friend>>(
  FriendsNotifier.new,
);
