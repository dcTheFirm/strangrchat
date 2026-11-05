import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hcaptcha_challenge_native.dart'
    if (dart.library.html) 'hcaptcha_challenge_web.dart'
    as platform;

const _defaultSiteKey = String.fromEnvironment('HCAPTCHA_SITE_KEY');
final hcaptchaSiteKeyProvider = Provider<String>((ref) => _defaultSiteKey);

abstract interface class CaptchaPresenter {
  Future<String?> verify(BuildContext context, String siteKey);
}

final captchaPresenterProvider = Provider<CaptchaPresenter>(
  (ref) => const _DefaultCaptchaPresenter(),
);

class _DefaultCaptchaPresenter implements CaptchaPresenter {
  const _DefaultCaptchaPresenter();

  @override
  Future<String?> verify(BuildContext context, String siteKey) =>
      HCaptchaChallenge.show(context, siteKey);
}

class HCaptchaChallenge {
  const HCaptchaChallenge._();

  static Future<String?> show(BuildContext context, String siteKey) =>
      platform.show(context, siteKey);
}
