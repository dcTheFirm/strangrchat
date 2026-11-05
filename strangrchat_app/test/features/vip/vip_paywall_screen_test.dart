import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strangrchat_app/features/vip/vip_paywall_screen.dart';

void main() {
  testWidgets('membership plans stack on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: VipPaywallScreen())),
    );
    await tester.pump();

    final passRect = tester.getRect(find.byKey(const Key('vip-plan-48-hours')));
    final monthlyRect = tester.getRect(
      find.byKey(const Key('vip-plan-monthly')),
    );
    expect(monthlyRect.top, greaterThan(passRect.bottom));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('membership plans stay side by side on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: VipPaywallScreen())),
    );
    await tester.pump();

    final passRect = tester.getRect(find.byKey(const Key('vip-plan-48-hours')));
    final monthlyRect = tester.getRect(
      find.byKey(const Key('vip-plan-monthly')),
    );
    expect(monthlyRect.left, greaterThan(passRect.left));
    expect(monthlyRect.top, closeTo(passRect.top, 2));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
