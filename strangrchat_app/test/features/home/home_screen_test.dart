import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strangrchat_app/app/theme.dart';
import 'package:strangrchat_app/features/home/home_screen.dart';

void main() {
  testWidgets('Home keeps matching visible and opens match settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Find someone'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.textContaining('Friends · preferences'), findsOneWidget);

    await tester.tap(find.text('Relationship'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('Relationship · preferences'), findsOneWidget);

    await tester.tap(find.byKey(const Key('match-filter-summary')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Match settings'), findsOneWidget);
    expect(find.text('Gender preferences'), findsOneWidget);
    expect(find.text('Same country'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Nearby'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Home remains usable with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Find someone'), findsOneWidget);
    final filterSummary = find.byKey(const Key('match-filter-summary'));
    await tester.ensureVisible(filterSummary);
    await tester.pump();
    await tester.tap(filterSummary);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Match settings'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Nearby'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
