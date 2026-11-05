import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strangrchat_app/core/network/auth_service.dart';
import 'package:strangrchat_app/features/onboarding/hcaptcha_challenge.dart';
import 'package:strangrchat_app/features/onboarding/profile_setup_screen.dart';

void main() {
  testWidgets('profile submission requires valid fields and hCaptcha token', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    final router = GoRouter(
      initialLocation: '/profile-setup',
      routes: [
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          hcaptchaSiteKeyProvider.overrideWithValue('test-site-key'),
          captchaPresenterProvider.overrideWithValue(_FakeCaptchaPresenter()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('profile-continue-button'));
    expect(tester.widget<InkWell>(continueButton).onTap, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-name')),
        matching: find.byType(TextFormField),
      ),
      'Sam',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-age')),
        matching: find.byType(TextFormField),
      ),
      '17',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-country')),
        matching: find.byType(TextFormField),
      ),
      'Canada',
    );
    expect(
      find.text('You must be at least 18 years old to use StrangrChat.'),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(continueButton).onTap, isNull);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-age')),
        matching: find.byType(TextFormField),
      ),
      '18',
    );
    final verifyButton = find.byKey(const Key('hcaptcha-verify-button'));
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(continueButton).onTap, isNotNull);

    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Home destination'), findsOneWidget);
    expect(authService.submittedName, 'Sam');
    expect(authService.submittedAge, 18);
    expect(authService.submittedCountry, 'Canada');
    expect(authService.submittedCity, isNull);
    expect(authService.submittedCaptchaToken, 'test-hcaptcha-token');
  });
}

class _FakeAuthService extends AuthService {
  String? submittedName;
  int? submittedAge;
  String? submittedCountry;
  String? submittedCity;
  String? submittedCaptchaToken;

  @override
  Future<AnonymousSession> completeProfile({
    required String name,
    required int age,
    required String country,
    required String captchaToken,
    String? city,
  }) async {
    submittedName = name;
    submittedAge = age;
    submittedCountry = country;
    submittedCity = city?.isEmpty == true ? null : city;
    submittedCaptchaToken = captchaToken;
    return const AnonymousSession(token: 'test-token', deviceId: 'test-device');
  }
}

class _FakeCaptchaPresenter implements CaptchaPresenter {
  @override
  Future<String?> verify(BuildContext context, String siteKey) async =>
      'test-hcaptcha-token';
}
