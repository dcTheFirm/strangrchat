import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/network/auth_service.dart';
import 'hcaptcha_challenge.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  String? _captchaToken;
  bool _isCaptchaVerified = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _formIsValid {
    final age = int.tryParse(_ageController.text.trim());
    return _nameController.text.trim().isNotEmpty &&
        age != null &&
        age >= 18 &&
        _countryController.text.trim().isNotEmpty &&
        _isCaptchaVerified &&
        ref.read(hcaptchaSiteKeyProvider).isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _ageController,
      _countryController,
    ]) {
      controller.addListener(_onFormChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _verifyHuman() async {
    if (_isSubmitting) return;
    final siteKey = ref.read(hcaptchaSiteKeyProvider);
    if (siteKey.isEmpty) {
      setState(() {
        _errorMessage = 'Verification is not configured for this build. Please contact support.';
      });
      return;
    }

    String? token;
    try {
      token = await ref.read(captchaPresenterProvider).verify(context, siteKey);
    } on PlatformException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load verification. Please try again.';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _captchaToken = token;
      _isCaptchaVerified = token != null && token.isNotEmpty;
      if (_isCaptchaVerified) _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formIsValid || _captchaToken == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .completeProfile(
            name: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            country: _countryController.text.trim(),
            captchaToken: _captchaToken!,
            city: _cityController.text.trim(),
          );
      if (mounted) context.go('/home');
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          _captchaToken = null;
          _isCaptchaVerified = false;
          _errorMessage = error.response?.statusCode == 403
              ? 'You must be at least 18 years old to use StrangrChat.'
              : error.response?.statusCode == 429
              ? 'Too many attempts. Please wait a few minutes before trying again.'
              : error.response?.statusCode == 400
              ? 'Verification expired or could not be confirmed. Please verify again.'
              : 'We couldn’t save your profile. Check your connection and try again.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _errorMessage =
              'The server response was incomplete. Please try again.';
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Secure sign-in couldn’t be saved on this device. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final siteKey = ref.watch(hcaptchaSiteKeyProvider);
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.bg, Color(0xFFFFE9DF), Color(0xFFF3E8F4)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 44,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back to consent',
                        onPressed: () => context.go('/'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTokens.surface,
                          foregroundColor: AppTokens.ink,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space12),
                    Text(
                      'A little about you',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      'Set up your anonymous profile to get started.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppTokens.muted),
                    ),
                    const SizedBox(height: AppTokens.space24),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: reduceMotion ? Duration.zero : AppTokens.slow,
                      curve: AppTokens.enter,
                      builder: (context, progress, child) => Opacity(
                        opacity: progress,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - progress)),
                          child: child,
                        ),
                      ),
                      child: _buildProfileForm(context, siteKey),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppTokens.space16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTokens.danger),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTokens.space20),
                    _ContinueButton(
                      enabled: _formIsValid && !_isSubmitting,
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppTokens.space12),
                    Text(
                      'Your profile is anonymous. City is optional and is not shown to other users.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, String siteKey) {
    final age = int.tryParse(_ageController.text.trim());
    final ageError = age != null && age < 18
        ? 'You must be at least 18 years old to use StrangrChat.'
        : null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileField(
            key: const Key('profile-name'),
            controller: _nameController,
            label: 'Name',
            hint: 'What should we call you?',
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Name is required.';
              if (name.length > 50) return 'Use 50 characters or fewer.';
              return null;
            },
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
          ),
          const SizedBox(height: AppTokens.space16),
          _ProfileField(
            key: const Key('profile-age'),
            controller: _ageController,
            label: 'Age',
            hint: '18 or older',
            errorText: ageError,
            validator: (value) {
              final age = int.tryParse(value?.trim() ?? '');
              if (age == null) return 'Enter your age in whole years.';
              if (age < 18) return 'You must be at least 18.';
              return null;
            },
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: AppTokens.space16),
          _ProfileField(
            key: const Key('profile-country'),
            controller: _countryController,
            label: 'Country',
            hint: 'Enter your country',
            validator: (value) {
              final country = value?.trim() ?? '';
              if (country.isEmpty) return 'Country is required.';
              if (country.length > 80) return 'Use 80 characters or fewer.';
              return null;
            },
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
          ),
          const SizedBox(height: AppTokens.space16),
          _ProfileField(
            key: const Key('profile-city'),
            controller: _cityController,
            label: 'City',
            hint: 'Optional',
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
          ),
          const SizedBox(height: AppTokens.space20),
          _buildCaptcha(context, siteKey),
        ],
      ),
    );
  }

  Widget _buildCaptcha(BuildContext context, String siteKey) {
    final siteKeyConfigured = siteKey.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius20),
        border: Border.all(color: AppTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Human verification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            siteKeyConfigured
                ? _isCaptchaVerified
                      ? 'You’re verified. The token will be checked securely when you continue.'
                      : 'Complete the image challenge before saving your profile.'
                : 'hCaptcha is not configured for this build. Add the public site key to enable verification.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space12),
          OutlinedButton.icon(
            key: const Key('hcaptcha-verify-button'),
            onPressed: siteKeyConfigured && !_isSubmitting
                ? _verifyHuman
                : null,
            icon: Icon(
              _isCaptchaVerified
                  ? Icons.verified_user_rounded
                  : Icons.image_search_rounded,
            ),
            label: Text(_isCaptchaVerified ? 'Verified' : 'Verify I’m human'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppTokens.surface,
        prefixIcon: Icon(_iconFor(label), color: AppTokens.coralDeep),
      ),
    );
  }

  IconData _iconFor(String fieldLabel) => switch (fieldLabel) {
    'Name' => Icons.person_outline_rounded,
    'Age' => Icons.cake_outlined,
    'Country' => Icons.public_rounded,
    _ => Icons.location_city_outlined,
  };
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTokens.base,
      curve: AppTokens.enter,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [AppTokens.coral, AppTokens.tangerine],
              )
            : null,
        color: enabled ? null : AppTokens.line,
        borderRadius: BorderRadius.circular(AppTokens.radius28),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppTokens.coral.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Continue',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('profile-continue-button'),
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppTokens.radius28),
            child: SizedBox(
              height: 56,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTokens.ink,
                        ),
                      )
                    : Text(
                        'Continue',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: enabled ? AppTokens.ink : AppTokens.muted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
