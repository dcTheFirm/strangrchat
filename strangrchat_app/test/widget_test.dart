// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:strangrchat_app/main.dart';
import 'package:strangrchat_app/core/network/auth_service.dart';

void main() {
  testWidgets('Onboarding 18+ verification smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(_FakeAuthService())],
        child: const StrangrChatApp(),
      ),
    );

    // Verify onboarding screen is shown with 18+ checkbox.
    expect(find.text('StrangrChat'), findsOneWidget);
    expect(
      find.text('I confirm that I am at least 18 years old.'),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .every((checkbox) => checkbox.value == false),
      isTrue,
    );

    // Button should be disabled initially
    final startButtonFinder = find.byType(ElevatedButton);
    expect(startButtonFinder, findsOneWidget);
    expect(tester.widget<ElevatedButton>(startButtonFinder).onPressed, isNull);

    // Tap the checkboxes
    final ageConsent = find.text('I confirm that I am at least 18 years old.');
    await tester.ensureVisible(ageConsent);
    await tester.tap(ageConsent);
    final termsConsent = find.text(
      'I agree to strict UGC Terms & Zero Tolerance for harassment or illegal content.',
    );
    await tester.ensureVisible(termsConsent);
    await tester.tap(termsConsent);
    await tester.pump();

    // Verify the explicit consent gate leads to profile setup.
    expect(
      tester.widget<ElevatedButton>(startButtonFinder).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(startButtonFinder);
    await tester.tap(startButtonFinder);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('A little about you'), findsOneWidget);
  });
}

class _FakeAuthService extends AuthService {
  @override
  Future<bool> hasCompletedProfile() async => false;
}
