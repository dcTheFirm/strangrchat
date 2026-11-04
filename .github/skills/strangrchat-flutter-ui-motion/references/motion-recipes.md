# Motion recipes for strangrchat (Flutter)

Starting points, not drop-in guarantees. Run `flutter analyze` and check package APIs against the versions in `pubspec.yaml`. Use `Color.withValues(alpha:)` (the repo already does), not `withOpacity`.

## Contents
1. Packages and assets
2. Tokens: Motion, Haptics, reduced motion, MotionQuality
3. PressableScale and SageButton
4. The Orb (idle, searching, match)
5. Circular-reveal route (Home to Chat)
6. Searching ripples and rotating copy
7. Match-found choreography
8. Chat: new-bubble entrance, grouping, typing dots
9. Two-tap Skip with ring countdown
10. Chat-ended dissolve
11. Sliding selector (intent, plans)
12. Toasts instead of SnackBars
13. Skeleton shimmer
14. Debug screenshot switch

## 1. Packages and assets

```yaml
dependencies:
  flutter_animate: ^4.5.0   # verify latest; entrances, stagger, shimmer
  animations: ^2.0.11       # official Flutter transitions; verify latest

flutter:
  fonts:
    - family: Bricolage
      fonts:
        - asset: assets/fonts/BricolageGrotesque-Variable.ttf   # verify licence and file name
    - family: Figtree
      fonts:
        - asset: assets/fonts/Figtree-Variable.ttf               # verify licence and file name
```

Variable fonts need `FontVariation('wght', 700)` in `TextStyle.fontVariations`, or ship static weights if you prefer simpler handling. Do not use `google_fonts` at runtime (privacy rule).

## 2. Tokens

```dart
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 380);
  static const hero = Duration(milliseconds: 900);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const move = Curves.easeInOutCubicEmphasized;
  static const snappy = SpringDescription(mass: 1, stiffness: 400, damping: 28);
  static const playful = SpringDescription(mass: 1, stiffness: 300, damping: 18);
}

abstract final class Haptics {
  static bool enabled = true; // bind to a persisted setting (secure storage is fine for a bool)
  static void tick() { if (enabled) HapticFeedback.selectionClick(); }
  static void light() { if (enabled) HapticFeedback.lightImpact(); }
  static void medium() { if (enabled) HapticFeedback.mediumImpact(); }
  static Future<void> matched() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }
}

extension MotionX on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

enum MotionTier { full, lite, minimal }

/// Picks a tier from real frame times. Start at full; drop if slow.
class MotionQuality {
  MotionQuality._();
  static final instance = MotionQuality._();
  final ValueNotifier<MotionTier> tier = ValueNotifier(MotionTier.full);
  final List<double> _ms = [];
  bool _watching = false;

  void startWatching() {
    if (_watching) return;
    _watching = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _ms.add(t.totalSpan.inMicroseconds / 1000);
    }
    if (_ms.length < 90) return; // ~1.5 s at 60 fps
    final avg = _ms.reduce((a, b) => a + b) / _ms.length;
    _ms.clear();
    if (avg > 24 && tier.value == MotionTier.full) tier.value = MotionTier.lite;
    else if (avg > 32 && tier.value == MotionTier.lite) tier.value = MotionTier.minimal;
  }
}
```

Only judge frames while an animated screen is showing (timings during idle are not meaningful). Let the user override the tier in Settings.

## 3. PressableScale and SageButton

```dart
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap, this.scale = 0.95});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);
  void _to(double v) => _c.animateWith(SpringSimulation(Motion.snappy, _c.value, v, _c.velocity));
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) { Haptics.light(); _to(widget.scale); },
        onTapUp: widget.onTap == null ? null : (_) { _to(1); widget.onTap!(); },
        onTapCancel: () => _to(1),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.scale(scale: _c.value, child: child),
          child: widget.child,
        ),
      );
}
```

`SageButton`: a `PressableScale` around a `DecoratedBox` with a flat forest-green fill (`#355E45`), radius full, `onPrimary` label (Figtree 16/600). Keep the shape and feedback tactile, not glossy. Disabled: `surfaceHigh` fill and `textMuted` label, with an `AnimatedContainer` (`Motion.base`) between states. Loading: `AnimatedSwitcher` swaps the label for a 20 px spinner in `onPrimary`. Wrap in `Semantics(button: true, label: ...)`.

## 4. The Orb

One painter, driven by one controller, three modes. Keep it in its own `RepaintBoundary`. Use a restrained sage gradient and faint halo; never use neon or high-saturation glow. Suggested light-theme colours: sage `#7E9C80`, light sage `#B8CEB8`; drive both from theme tokens in production and keep `glowAlpha` subtle (about 0.08–0.14).

```dart
enum OrbMode { idle, searching, matched }

class OrbPainter extends CustomPainter {
  OrbPainter({required this.t, required this.mode, required this.sage, required this.sageLight, required this.glowAlpha})
      : super(repaint: t);
  final Animation<double> t; // 0..1 looping
  final OrbMode mode;
  final Color sage, sageLight;
  final double glowAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.28;
    final breathe = 1 + 0.04 * (0.5 - 0.5 * math.cos(t.value * 2 * math.pi));
    // glow
    canvas.drawCircle(c, r * 1.9 * breathe, Paint()
      ..shader = RadialGradient(colors: [sage.withValues(alpha: glowAlpha), sage.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r * 1.9 * breathe)));
    // body
    canvas.drawCircle(c, r * breathe, Paint()
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [sageLight, sage])
          .createShader(Rect.fromCircle(center: c, radius: r)));
    if (mode == OrbMode.searching) {
      for (var i = 0; i < 3; i++) {
        final p = (t.value + i / 3) % 1.0;
        canvas.drawCircle(c, r + (size.shortestSide * 0.35) * Curves.easeOut.transform(p), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = sage.withValues(alpha: (1 - p) * 0.45));
      }
    }
  }

  @override
  bool shouldRepaint(OrbPainter old) => old.mode != mode || old.sage != sage || old.sageLight != sageLight || old.glowAlpha != glowAlpha;
}
```

Add `import 'dart:math' as math;`. Lite tier: skip the glow gradient shader (use a flat translucent circle) and use 2 rings. Minimal tier: static orb, no loop (do not start the controller).

Usage: a controller `..repeat(period: const Duration(milliseconds: 4000))` for idle, 2400 ms for searching; change the period when mode changes (`controller.duration = ...; controller.repeat()`). Home's Orb is wrapped in `PressableScale` with `scale: 0.9`.

## 5. Circular-reveal route (Home to Chat)

```dart
CustomTransitionPage<void> orbRevealPage({required Widget child, required Offset origin, required LocalKey key}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubicEmphasized);
      return AnimatedBuilder(
        animation: curved,
        builder: (_, __) => ClipPath(
          clipper: _CircleReveal(origin, curved.value),
          child: child,
        ),
      );
    },
  );
}

class _CircleReveal extends CustomClipper<Path> {
  _CircleReveal(this.origin, this.t);
  final Offset origin; final double t;
  @override
  Path getClip(Size s) {
    final maxR = (Offset(s.width, s.height) - Offset.zero).distance; // safe upper bound
    return Path()..addOval(Rect.fromCircle(center: origin, radius: maxR * t));
  }
  @override
  bool shouldReclip(_CircleReveal o) => o.t != t || o.origin != origin;
}
```

Capture the Orb centre with a `GlobalKey` before `context.push('/chat', extra: origin)` and read `state.extra` in the route's `pageBuilder`. When `context.reduceMotion` is true, use `FadeThroughTransition` instead.

## 6. Searching ripples and rotating copy

Ripples are in the Orb painter (section 4). Rotating copy:

```dart
class RotatingCopy extends StatefulWidget {
  const RotatingCopy({super.key, required this.lines});
  final List<String> lines;
  @override
  State<RotatingCopy> createState() => _RotatingCopyState();
}

class _RotatingCopyState extends State<RotatingCopy> {
  int _i = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) setState(() => _i = (_i + 1) % widget.lines.length);
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: Motion.slow,
        transitionBuilder: (c, a) => FadeTransition(opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a), child: c)),
        child: Text(widget.lines[_i], key: ValueKey(_i), textAlign: TextAlign.center),
      );
}
```

Add `import 'dart:async';`. Show the long-wait card after 20 s with a second `Timer` cancelled on dispose.

## 7. Match-found choreography

One controller, `Interval`s, tap to skip.

```dart
class MatchReveal extends StatefulWidget {
  const MatchReveal({super.key, required this.me, required this.them, required this.onDone});
  final Color me, them; final VoidCallback onDone;
  @override
  State<MatchReveal> createState() => _MatchRevealState();
}

class _MatchRevealState extends State<MatchReveal> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final slide = CurvedAnimation(parent: c, curve: const Interval(0.0, .45, curve: Curves.easeOutBack));
  late final glow = CurvedAnimation(parent: c, curve: const Interval(.4, .7, curve: Curves.easeOut));
  late final text = CurvedAnimation(parent: c, curve: const Interval(.55, .85, curve: Curves.easeOut));
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    c.addListener(() {
      if (!_buzzed && c.value >= .45) { _buzzed = true; Haptics.matched(); }
    });
    c.forward().whenComplete(() { if (mounted) widget.onDone(); });
  }
  @override
  void dispose() { c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => c.animateTo(1, duration: Motion.fast),
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) {
            final d = 90 * (1 - slide.value); // distance from centre
            return Stack(alignment: Alignment.center, children: [
              Opacity(opacity: glow.value, child: _Glow(color: widget.me)),
              Transform.translate(offset: Offset(-d - 36, 0), child: AvatarOrb(color: widget.me)),
              Transform.translate(offset: Offset(d + 36, 0), child: AvatarOrb(color: widget.them)),
              Positioned(bottom: 0, child: Opacity(opacity: text.value, child: const Text('Connected'))),
            ]);
          },
        ),
      );
}
```

`AvatarOrb` is a small painter: a gradient circle seeded from a hash of the room id (generated on device, never stored). `_Glow` is a radial gradient. Announce "Connected to a stranger" with `SemanticsService.announce`.

## 8. Chat motion

Only newly arrived messages animate. `ListView.builder` recycles items, so track seen ids in State:

```dart
final _seen = <String>{};

Widget _item(ChatMessage m, bool groupedWithNext) {
  final isNew = _seen.add(m.id); // true the first time we build this id
  final bubble = ChatBubble(msg: m, showTail: !groupedWithNext);
  if (!isNew || context.reduceMotion) return bubble;
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(m.isMe ? 14 * (1 - v) : -14 * (1 - v), 12 * (1 - v)), child: child),
    ),
    child: bubble,
  );
}
```

Clear `_seen` when a new chat starts. Group consecutive messages by `isMe` and a time gap under about 2 minutes; show the tail only on the last of a group.

Typing dots (only if the server emits a typing event; do not invent one):

```dart
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});
  @override
  State<TypingDots> createState() => _TypingDotsState();
}
class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: c,
            builder: (_, __) {
              final p = (c.value - i * .15) % 1.0;
              final y = -4 * (p < .5 ? Curves.easeOut.transform(p * 2) : 1 - Curves.easeIn.transform((p - .5) * 2));
              return Transform.translate(offset: Offset(0, y), child: const _Dot());
            },
          ),
      ]);
}
```

Send button: `AnimatedContainer` fill from muted to forest green when the field has text; on send, a quick scale bounce (`PressableScale` with `scale: .85`) and the sent forest-green bubble enters. Profanity warning: an inline banner above the composer that slides down 8 px and shakes horizontally once (`TweenAnimationBuilder` with a damped sine) tinted `danger`.

## 9. Two-tap Skip with ring countdown

Because chats are unrecoverable, make skipping deliberate.

```dart
class SkipCapsule extends StatefulWidget {
  const SkipCapsule({super.key, required this.onSkip});
  final VoidCallback onSkip;
  @override
  State<SkipCapsule> createState() => _SkipCapsuleState();
}

class _SkipCapsuleState extends State<SkipCapsule> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  bool armed = false;

  @override
  void initState() {
    super.initState();
    c.addStatusListener((s) { if (s == AnimationStatus.completed && mounted) setState(() => armed = false); });
  }
  @override
  void dispose() { c.dispose(); super.dispose(); }

  void _tap() {
    if (!armed) { Haptics.light(); setState(() => armed = true); c.forward(from: 0); }
    else { Haptics.medium(); c.stop(); setState(() => armed = false); widget.onSkip(); }
  }

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: _tap,
        child: AnimatedContainer(
          duration: Motion.base,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: armed ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          child: AnimatedSwitcher(
            duration: Motion.fast,
            child: Text(armed ? 'Tap again to skip' : 'Next', key: ValueKey(armed)),
          ),
        ),
      );
}
```

Draw the countdown ring as a `CustomPaint` stroke in a muted sage tone, sweeping with `c.value` around the capsule. Add `Semantics(button: true, label: armed ? 'Confirm skip' : 'Skip to next stranger')`.

## 10. Chat-ended dissolve

Use a calm, soft fade rather than a flame or fire metaphor. Stagger bubbles from last to first: opacity 1 to 0, translateY 0 to -24, scale 1 to .96, 40 ms offsets, 500 ms each, with `flutter_animate`:

```dart
bubble.animate(delay: (40 * indexFromEnd).ms)
      .fadeOut(duration: 500.ms, curve: Curves.easeIn)
      .moveY(end: -24, duration: 500.ms)
      .scaleXY(end: .96, duration: 500.ms);
```

Do not blur each bubble (expensive). If you want blur, apply one `ImageFiltered` to the whole list for the last 300 ms, and only on the full tier. After the gentle fade, clear the messages from state and show the end panel ("Chat ended. Nothing was saved.") with a `Find next` SageButton and an optional Add friend ghost button.

## 11. Sliding selector (intent, VIP plans)

One highlight that moves between options, instead of per-item colour flips.

```dart
class SlidingSelector extends StatelessWidget {
  const SlidingSelector({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels; final int index; final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth / labels.length;
      return Stack(children: [
        AnimatedPositioned(
          duration: Motion.base, curve: Motion.enter,
          left: w * index, width: w, top: 0, bottom: 0,
          child: DecoratedBox(decoration: ShapeDecoration(shape: const StadiumBorder(), color: cs.primary)),
        ),
        Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () { Haptics.tick(); onChanged(i); },
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: AnimatedDefaultTextStyle(
                  duration: Motion.base,
                  style: TextStyle(color: i == index ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  child: Text(labels[i]))))),
        ]),
      ]);
    });
  }
}
```

Four labels like "Relationship" may be too wide for equal columns; if so, make the row horizontally scrollable and animate the highlight by measured item rects instead.

## 12. Toasts instead of SnackBars

Use an `OverlayEntry` host (or a package-free `ToastHost` widget above the router) that shows a top pill: slide down 16 px plus fade with a spring, auto-dismiss at 2.4 s, swipe up to dismiss, one at a time with a queue. Variants: info (surface plus outline), success (deep green), danger (danger colour with icon). Always an icon plus text, never colour alone. Announce with `SemanticsService.announce`.

## 13. Skeleton shimmer

```dart
Widget skeleton(BuildContext context, {double h = 64, double r = 20}) {
  final cs = Theme.of(context).colorScheme;
  return Container(height: h, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(r)))
      .animate(onPlay: (c) => c.repeat())
      .shimmer(duration: 1200.ms, color: cs.surface.withValues(alpha: .5));
}
```

Skip the shimmer on the minimal tier and when reduced motion is on.

## 14. Debug screenshot switch

```dart
const allowScreenshots = bool.fromEnvironment('ALLOW_SCREENSHOTS');

// main.dart
if (!allowScreenshots) {
  try { await ScreenProtector.preventScreenshotOn(); } catch (e) { debugPrint('...$e'); }
}
```

Run with `flutter run --dart-define=ALLOW_SCREENSHOTS=true` for design review only. Never set it in release builds or CI release pipelines.
