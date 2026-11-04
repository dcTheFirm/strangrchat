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

void main() {
  testWidgets('Onboarding 18+ verification smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: StrangrChatApp()));

    // Verify onboarding screen is shown with 18+ checkbox.
    expect(find.text('StrangrChat'), findsOneWidget);
    expect(find.text('I confirm that I am at least 18 years old.'), findsOneWidget);

    // Button should be disabled initially
    final startButtonFinder = find.byType(ElevatedButton);
    expect(startButtonFinder, findsOneWidget);
    
    // Tap the checkboxes
    await tester.tap(find.text('I confirm that I am at least 18 years old.'));
    await tester.tap(find.text('I agree to strict UGC Terms & Zero Tolerance for harassment or illegal content.'));
    await tester.pump();

    // Verify button is enabled and tappable, leading to Home screen
    await tester.tap(startButtonFinder);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Ready when you are'), findsOneWidget);
  });
}

