import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strangrchat_app/app/theme.dart';
import 'package:strangrchat_app/features/home/home_screen.dart';
import 'package:strangrchat_app/features/notifications/notifications_screen.dart';

void main() {
  testWidgets('notification screen states backend inbox is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(
      find.text(
        'Notifications aren’t available yet. When the inbox is connected, verified updates will appear here.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Private chat messages are never shown in notifications.'),
      findsOneWidget,
    );
    expect(find.text('No new notifications yet'), findsNothing);
  });

  testWidgets('home bell opens the notification route', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'Notifications aren’t available yet. When the inbox is connected, verified updates will appear here.',
      ),
      findsOneWidget,
    );
  });
}
