import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/sticker_avatar.dart';
import '../../app/tokens.dart';
import '../../core/network/auth_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _is18PlusChecked = false;
  bool _isUgcTermsChecked = false;
  bool _isContinuing = false;

  bool get _canProceed => _is18PlusChecked && _isUgcTermsChecked;

  Future<void> _continue() async {
    if (!_canProceed || _isContinuing) return;
    setState(() => _isContinuing = true);
    try {
      final hasCompletedProfile = await ref
          .read(authServiceProvider)
          .hasCompletedProfile();
      if (!mounted) return;
      context.go(hasCompletedProfile ? '/home' : '/profile-setup');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn’t continue. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.bg, Color(0xFFFFE6E0), Color(0xFFF3E2F3)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTokens.navDark,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            size: 23,
                            color: AppTokens.tangerine,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'StrangrChat',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _StickerOrbit(),
                    const SizedBox(height: 23),
                    Text.rich(
                      TextSpan(
                        text: 'Meet someone new.\n',
                        children: const [
                          TextSpan(
                            text: 'Keep it kind.',
                            style: TextStyle(color: AppTokens.coralDeep),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A lighthearted place for real-time conversations, with your privacy in mind.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppTokens.muted),
                    ),
                    const SizedBox(height: 20),
                    Material(
                      color: AppTokens.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radius20),
                        side: const BorderSide(color: AppTokens.line),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _is18PlusChecked,
                              onChanged: (value) => setState(
                                () => _is18PlusChecked = value ?? false,
                              ),
                              activeColor: AppTokens.coralDeep,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'I confirm that I am at least 18 years old.',
                              ),
                            ),
                            const Divider(height: 1, color: AppTokens.line),
                            CheckboxListTile(
                              value: _isUgcTermsChecked,
                              onChanged: (value) => setState(
                                () => _isUgcTermsChecked = value ?? false,
                              ),
                              activeColor: AppTokens.coralDeep,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'I agree to strict UGC Terms & Zero Tolerance for harassment or illegal content.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _canProceed && !_isContinuing
                          ? _continue
                          : null,
                      icon: const Icon(Icons.favorite_rounded, size: 19),
                      label: Text(
                        _isContinuing ? 'One moment…' : 'Find someone',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.coralDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTokens.line,
                        disabledForegroundColor: AppTokens.muted,
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '18+ only  ·  Be respectful  ·  Leave any chat at any time',
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
}

class _StickerOrbit extends StatelessWidget {
  const _StickerOrbit();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.32,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.peach, AppTokens.blush, AppTokens.lavender],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTokens.surface.withValues(alpha: 0.8)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _OrbitPainter()),
                ),
                StickerAvatar(variant: 0, size: scale * 0.28),
                Positioned(
                  left: scale * 0.12,
                  top: scale * 0.11,
                  child: StickerAvatar(variant: 1, size: scale * 0.21),
                ),
                Positioned(
                  right: scale * 0.12,
                  top: scale * 0.13,
                  child: StickerAvatar(variant: 2, size: scale * 0.20),
                ),
                Positioned(
                  left: scale * 0.10,
                  bottom: scale * 0.09,
                  child: StickerAvatar(variant: 3, size: scale * 0.19),
                ),
                Positioned(
                  right: scale * 0.11,
                  bottom: scale * 0.09,
                  child: StickerAvatar(variant: 0, size: scale * 0.20),
                ),
                Positioned(
                  top: scale * 0.08,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTokens.coralDeep,
                    size: 19,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    final paint = Paint()
      ..color = AppTokens.coralDeep.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var index = 0; index < 36; index++) {
      final angle = 2 * math.pi * index / 36;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(point, size.shortestSide * 0.0045, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => false;
}
