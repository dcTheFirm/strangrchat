# Motion recipes for strangrchat (Flutter)

Starting points, not drop-in guarantees. Run `flutter analyze` and check package APIs against the versions in `pubspec.yaml`. Use `Color.withValues(alpha:)` (the repo already does), not `withOpacity`.

## Contents
1. Packages and assets
2. Tokens: Motion, Haptics, reduced motion, MotionQuality
3. PressableScale and SageButton
4. The supporting Orb (searching and match)
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
    - family: CormorantGaramond
      fonts:
        - asset: assets/fonts/CormorantGaramond-Variable.ttf   # verify licence and file name
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

`SageButton`: a `PressableScale` around a `DecoratedBox` with the flat deep-forest fill (`forest`), restrained radius (not necessarily pill-shaped), `onForest` label (Figtree 16/600). Disabled: `surfaceHigh` fill and `textMuted` label, with an `AnimatedContainer` (`Motion.base`) between states. Loading: `AnimatedSwitcher` swaps the label for a 20 px spinner in `onForest`. Wrap in `Semantics(button: true, label: ...)`.

## 4. The Orb

One painter, driven by one controller, three modes. Keep it in its own `RepaintBoundary`.

```dart
enum OrbMode { idle, searching, matched }

class OrbPainter extends CustomPainter {
  OrbPainter({required this.t, required this.mode, required this.sage, required this.sageSoft, required this.glowAlpha})
      : super(repaint: t);
  final Animation<double> t; // 0..1 looping
  final OrbMode mode;
  final Color sage, sageSoft;
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
      ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [sageSoft, sage])
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
  bool shouldRepaint(OrbPainter old) => old.mode != mode || old.sage != sage || old.sageSoft != sageSoft || old.glowAlpha != glowAlpha;
}
```

Add `import 'dart:math' as math;`. Lite tier: skip the glow gradient shader (use a flat translucent circle) and use 2 rings. Minimal tier: static orb, no loop (do not start the controller).

Usage: a controller `..repeat(period: const Duration(milliseconds: 4000))` for idle, 2400 ms for searching; change the period when mode changes (`controller.duration = ...; controller.repeat()`). Do not make the Orb the Home primary CTA; the Home screen follows the editorial headline + Start a random chat CTA. Use the Orb as a supporting searching/matching visual.

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

Capture the primary CTA centre (or use a simple fade-through) with a `GlobalKey` before `context.push('/chat', extra: origin)` and read `state.extra` in the route's `pageBuilder`. When `context.reduceMotion` is true, use `FadeThroughTransition` instead.

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
  const MatchReveal({super.key, required this.meStickerId, required this.themStickerId, required this.onDone});
  final String meStickerId, themStickerId; final VoidCallback onDone;
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
              Opacity(
                opacity: glow.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: .10),
                  ),
                ),
              ),
              Transform.translate(offset: Offset(-d - 36, 0), child: StickerAvatar(stickerId: widget.meStickerId)),
              Transform.translate(offset: Offset(d + 36, 0), child: StickerAvatar(stickerId: widget.themStickerId)),
              Positioned(bottom: 0, child: Opacity(opacity: text.value, child: const Text('Connected'))),
            ]);
          },
        ),
      );
}
```

`StickerAvatar` uses the stable profile sticker asset ID for each participant; it is not a generated face or a randomly chosen asset on each rebuild. Keep the match highlight as a small sage tint, not a large glowing gradient. Announce "Connected to a stranger" with `SemanticsService.announce`.

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

Send button: `AnimatedContainer` fill from muted to forest when the field has text; on send, a quick scale bounce (`PressableScale` with `scale: .85`) and the sent bubble enters. Profanity warning: an inline banner above the composer that slides down 8 px and shakes horizontally once (`TweenAnimationBuilder` with a damped sine) tinted `danger`.

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

Draw the countdown ring as a `CustomPaint` stroke sweeping with `c.value` around the capsule. Add `Semantics(button: true, label: armed ? 'Confirm skip' : 'Skip to next stranger')`.

## 10. Chat-ended dissolve

Stagger bubbles from last to first: opacity 1 to 0, translateY 0 to -24, scale 1 to .96, 40 ms offsets, 500 ms each, with `flutter_animate`:

```dart
bubble.animate(delay: (40 * indexFromEnd).ms)
      .fadeOut(duration: 500.ms, curve: Curves.easeIn)
      .moveY(end: -24, duration: 500.ms)
      .scaleXY(end: .96, duration: 500.ms);
```

Do not blur each bubble (expensive). If you want blur, apply one `ImageFiltered` to the whole list for the last 300 ms, and only on the full tier. After the dissolve, clear the messages from state and show the end panel ("Chat ended. Nothing was saved.") with a `Find next` SageButton and an optional Add friend ghost button.

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

Use an `OverlayEntry` host (or a package-free `ToastHost` widget above the router) that shows a top pill: slide down 16 px plus fade with a spring, auto-dismiss at 2.4 s, swipe up to dismiss, one at a time with a queue. Variants: info (surface plus outline), success (mint), danger (danger colour with icon). Always an icon plus text, never colour alone. Announce with `SemanticsService.announce`.

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


## 15. Notification bell and inbox

The bell itself should be quiet until it has unread activity. Keep the badge small and aligned to the top-right; use a semantic label such as `Notifications, 3 unread`.

```dart
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.unreadCount, required this.onTap});
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: unreadCount == 0 ? 'Notifications' : 'Notifications, $unreadCount unread',
      child: IconButton(
        tooltip: 'Notifications',
        onPressed: onTap,
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}
```

Inbox motion: on wide layouts, slide the panel in from the right over a dimmed scrim (about 220–280 ms); on phones, use a modal bottom sheet or full-screen route with a short fade/slide. Animate each unread marker only when its read state changes. Rows may enter with a subtle 20–30 ms stagger on first load, but do not continuously animate the badge. `Mark all as read` should show loading and confirmed/error states; do not optimistically erase unread markers unless the data layer supports rollback.

Use actual event types only (friend request, message request, new match, subscription status, expiry reminder when supported). Do not show private message text in the notification row or push preview. This section defines UI motion only; the event contract, inbox persistence, read endpoint, and push routing must be confirmed with the backend first.

## 16. Stable sticker avatars

Profile identity is a bundled goofy sticker, never a user portrait. The sticker ID is assigned once during profile creation and read from profile state everywhere.

```dart
class StickerAvatar extends StatelessWidget {
  const StickerAvatar({super.key, required this.stickerId, this.size = 48});
  final String stickerId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sticker = StickerAssets.byId(stickerId); // deterministic lookup; no random call here
    return Semantics(
      image: true,
      label: 'Profile sticker: ${sticker.accessibleName}',
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(sticker.assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
```

A tiny one-time scale/fade on first display is enough. Do not rotate, shuffle, or reassign the sticker on rebuild, tab change, app restart, or notification refresh. Use a local, licensed asset pack. Keep chat-image handling separate: chat images remain ephemeral and must not become profile avatars.

## 17. Matching filter interactions

- There is no distance/radius control. Do not animate or render a radius slider, nearby chip, kilometre value, or “increase distance” prompt.
- The replacement control is a compact Same country switch. Animate its thumb/fill with `Motion.base`; the label and semantic value must announce enabled/disabled. Do not trigger GPS permission.
- Female gender-filter usage may show a small text count such as “3 free uses left” when the server provides it. Keep the counter static; no count-up gimmick. On exhaustion, transition to the subscription explanation with a simple fade/slide. Do not invent a reset timer or locally decrement a count unless the server contract explicitly says when a use is consumed.
- If the remaining allowance or Same country enforcement is not available from the service, keep the UI in an explicit unavailable/coming-soon state only if the product owner approves it; do not imply the feature is active.
