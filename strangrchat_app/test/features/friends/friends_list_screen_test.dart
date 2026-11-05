import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strangrchat_app/core/network/api_client.dart';
import 'package:strangrchat_app/core/network/friend_service.dart';
import 'package:strangrchat_app/features/friends/friends_list_screen.dart';

void main() {
  testWidgets('a rejected friends request shows an error without retrying', (
    tester,
  ) async {
    final service = _UnauthorizedFriendService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [friendServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: FriendsListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Friends could not load'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(service.loadCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(service.loadCalls, 2);
  });
}

class _UnauthorizedFriendService extends FriendService {
  _UnauthorizedFriendService() : super(ApiClient());

  int loadCalls = 0;

  @override
  Future<FriendsSnapshot> load() async {
    loadCalls++;
    final requestOptions = RequestOptions(path: '/friends');
    throw DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 401),
    );
  }
}
