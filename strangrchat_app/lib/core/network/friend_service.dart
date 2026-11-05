import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'auth_service.dart';

class FriendSummary {
  const FriendSummary({
    required this.id,
    required this.name,
    required this.connectedAt,
  });

  final String id;
  final String name;
  final DateTime connectedAt;

  factory FriendSummary.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Friend response is invalid.');
    }
    return FriendSummary(
      id: id,
      name: name,
      connectedAt: _FriendDate.parse(json['connectedAt']),
    );
  }
}

class FriendRequestSummary {
  const FriendRequestSummary({
    required this.requestId,
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String requestId;
  final String id;
  final String name;
  final DateTime createdAt;

  factory FriendRequestSummary.fromJson(Map<String, dynamic> json) {
    final requestId = json['requestId'];
    final id = json['id'];
    final name = json['name'];
    if (requestId is! String || id is! String || name is! String) {
      throw const FormatException('Friend request response is invalid.');
    }
    return FriendRequestSummary(
      requestId: requestId,
      id: id,
      name: name,
      createdAt: _FriendDate.parse(json['createdAt']),
    );
  }
}

class FriendsSnapshot {
  const FriendsSnapshot({
    required this.friends,
    required this.incomingRequests,
    required this.outgoingRequests,
  });

  final List<FriendSummary> friends;
  final List<FriendRequestSummary> incomingRequests;
  final List<FriendRequestSummary> outgoingRequests;

  factory FriendsSnapshot.fromJson(Map<String, dynamic> json) =>
      FriendsSnapshot(
        friends: _decodeList(json['friends'], FriendSummary.fromJson),
        incomingRequests: _decodeList(
          json['incomingRequests'],
          FriendRequestSummary.fromJson,
        ),
        outgoingRequests: _decodeList(
          json['outgoingRequests'],
          FriendRequestSummary.fromJson,
        ),
      );
}

class FriendService {
  FriendService(this._apiClient);

  final ApiClient _apiClient;

  Future<FriendsSnapshot> load() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/friends');
    final data = response.data;
    if (data == null) throw const FormatException('Friends response is empty.');
    return FriendsSnapshot.fromJson(data);
  }

  Future<void> sendRequest(String friendId) async {
    await _apiClient.post<void>(
      '/friends/requests',
      data: {'toUserId': friendId},
    );
  }

  Future<void> acceptRequest(String requestId) async {
    await _apiClient.post<void>('/friends/requests/$requestId/accept');
  }

  Future<void> rejectRequest(String requestId) async {
    await _apiClient.delete<void>('/friends/requests/$requestId');
  }

  Future<void> block(String friendId) async {
    await _apiClient.post<void>('/friends/$friendId/block');
  }

  Future<void> report(String friendId, String reason) async {
    await _apiClient.post<void>(
      '/reports',
      data: {'reportedUserId': friendId, 'reason': reason},
    );
  }
}

List<T> _decodeList<T>(dynamic value, T Function(Map<String, dynamic>) decode) {
  if (value is! List) {
    throw const FormatException('Friends response list is invalid.');
  }
  return value
      .map((item) {
        if (item is! Map) {
          throw const FormatException('Friends response item is invalid.');
        }
        return decode(Map<String, dynamic>.from(item));
      })
      .toList(growable: false);
}

class _FriendDate {
  static DateTime parse(dynamic value) {
    if (value is! String) {
      throw const FormatException('Friends response timestamp is invalid.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('Friends response timestamp is invalid.');
    }
    return parsed;
  }
}

final friendServiceProvider = Provider<FriendService>(
  (ref) => FriendService(ref.watch(apiClientProvider)),
);
final friendsProvider = FutureProvider<FriendsSnapshot>(
  (ref) => ref.watch(friendServiceProvider).load(),
  retry: (retryCount, error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode < 500) return null;
    }

    if (retryCount >= 2) return null;
    return Duration(milliseconds: 200 * (1 << retryCount));
  },
);
