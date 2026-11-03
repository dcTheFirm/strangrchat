import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/network/auth_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _is18PlusChecked = false;
  bool _isUgcTermsChecked = false;

  bool get _canProceed => _is18PlusChecked && _isUgcTermsChecked;

  @override
  void initState() {
    super.initState();
    // Anonymous auth is intentionally silent; matchmaking retries it if the
    // server was not running while the user was reading onboarding.
    unawaited(_startAnonymousSession());
  }

  Future<void> _startAnonymousSession() async {
    try {
      await ref.read(authServiceProvider).ensureAnonymousSession();
    } catch (error) {
      debugPrint('Anonymous session bootstrap deferred: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo / Title
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.softBlush,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 48,
                    color: AppTheme.primaryCoral,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'StrangrChat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mainText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anonymous, zero-storage real-time connections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                ),
              ),
              const Spacer(),

              // Safety Gate / Checkboxes
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _is18PlusChecked,
                        onChanged: (val) {
                          setState(() {
                            _is18PlusChecked = val ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryCoral,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'I confirm that I am at least 18 years old.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mainText,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.border),
                    Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _isUgcTermsChecked,
                        onChanged: (val) {
                          setState(() {
                            _isUgcTermsChecked = val ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryCoral,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'I agree to strict UGC Terms & Zero Tolerance for harassment or illegal content.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mainText,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Enter Button
              ElevatedButton(
                onPressed: _canProceed
                    ? () {
                        context.go('/home');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCoral,
                  disabledBackgroundColor: AppTheme.border,
                ),
                child: const Text('Start Connecting'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
