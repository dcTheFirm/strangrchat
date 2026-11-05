# Motion recipes for StrangrChat — Peach Pop (Flutter)

These are implementation patterns, not guaranteed drop-ins. Match the actual Flutter/Dart versions in `pubspec.yaml`, run `dart format`, `flutter analyze`, and tests. Prefer built-in Flutter animation APIs first. Use `Color.withValues(alpha:)`, not deprecated `withOpacity`.

## Contents

1. Motion, haptics, reduced motion
2. Pressable CTA
3. Sticker avatar float and orbit
4. Discovery card swipe
5. Match celebration
6. Page transitions
7. Chat bubble entrance and grouping
8. Typing indicator
9. Double-tap Next/Skip
10. Toasts and skeletons
11. Screen screenshot protection debug switch

## 1. Tokens, haptics, reduced motion

```dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
  static const hero = Duration(milliseconds: 720);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const move = Curves.easeInOutCubic;
}

abstract final class Haptics {
  static bool enabled = true; // Bind to a real user preference if one exists.
  static void tick() { if (enabled) HapticFeedback.selectionClick(); }
  static void light() { if (enabled) HapticFeedback.lightImpact(); }
  static void medium() { if (enabled) HapticFeedback.mediumImpact(); }
  static Future<void> matched() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 75));
    await HapticFeedback.lightImpact();
  }
}

extension MotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

enum MotionTier { full, lite, minimal }

class MotionQuality {
  MotionQuality._();
  static final instance = MotionQuality._();
  final ValueNotifier<MotionTier> tier = ValueNotifier(MotionTier.full);
  final List<double> _frameMs = [];
  bool _watching = false;

  void startWatching() {
    if (_watching) return;
    _watching = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stopWatching() {
    if (!_watching) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _watching = false;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final frame in timings) {
      _frameMs.add(frame.totalSpan.inMicroseconds / 1000);
    }
    if (_frameMs.length < 90) return;
    final average = _frameMs.reduce((a, b) => a + b) / _frameMs.length;
    _frameMs.clear();
    if (average > 24 && tier.value == MotionTier.full) {
      tier.value = MotionTier.lite;
    } else if (average > 32 && tier.value == MotionTier.lite) {
      tier.value = MotionTier.minimal;
    }
  }
}
```

Only measure while an animated screen is visible; idle frame timings are misleading. Let users choose a lower tier if a setting exists. Always obey system reduced motion regardless of the tier.

## 2. Pressable CTA

Use a small spring/scale response; avoid a large bounce. The bright CTA gradient may need dark text to meet contrast. Use the shared theme tokens instead of hardcoded colours in production.

```dart
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap, this.scale = .97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  void _to(double value) {
    _controller.animateTo(value, duration: Motion.fast, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null || context.reduceMotion
            ? null
            : (_) { Haptics.light(); _to(widget.scale); },
        onTapUp: widget.onTap == null
            ? null
            : (_) { _to(1); widget.onTap!(); },
        onTapCancel: () => _to(1),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => Transform.scale(
            scale: context.reduceMotion ? 1 : _controller.value,
            child: child,
          ),
          child: widget.child,
        ),
      );
}
```

Wrap the `PressableScale` child with a semantic button label, disabled state, and visible focus treatment. Loading morphs the text to a compact progress indicator; it must not change the operation's success state prematurely.

## 3. Sticker avatar float and orbit

A sticker is identified by a stable `stickerId`. Resolve it through an asset registry (`Map<String, String>` or equivalent). Never call `Random()` from `build()` and never pick a new ID on each animation tick.

A simple low-cost float for a hero sticker:

```dart
class FloatingSticker extends StatefulWidget {
  const FloatingSticker({super.key, required this.child});
  final Widget child;

  @override
  State<FloatingSticker> createState() => _FloatingStickerState();
}

class _FloatingStickerState extends State<FloatingSticker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, context.reduceMotion ? 0 : -5 * _controller.value),
          child: child,
        ),
      );
}
```

For onboarding orbit compositions, prefer `CustomPainter` or a `Stack` with a small fixed set of sticker positions. Use one shared controller for the orbit; keep the sticker widgets static children of `AnimatedBuilder`. In lite mode reduce orbiting items; in minimal/reduced-motion mode show the stickers statically. Do not add more than one continuous loop to a screen.

## 4. Discovery card swipe

Use the current product's actual swipe/like/pass provider action. A visual drag must not create a fake match. Add visible pass/like buttons for accessibility and one-handed use.

```dart
class SwipeCardMotion extends StatefulWidget {
  const SwipeCardMotion({super.key, required this.child, required this.onPass, required this.onLike});
  final Widget child;
  final VoidCallback onPass;
  final VoidCallback onLike;

  @override
  State<SwipeCardMotion> createState() => _SwipeCardMotionState();
}

class _SwipeCardMotionState extends State<SwipeCardMotion> {
  Offset _offset = Offset.zero;
  bool _locked = false;

  void _finish(bool like) {
    if (_locked) return;
    _locked = true;
    Haptics.medium();
    if (like) { widget.onLike(); } else { widget.onPass(); }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: context.reduceMotion || _locked
          ? null
          : (details) => setState(() => _offset += details.delta),
      onPanEnd: context.reduceMotion || _locked
          ? null
          : (_) {
              if (_offset.dx.abs() < 90) {
                setState(() => _offset = Offset.zero);
                return;
              }
              _finish(_offset.dx > 0);
            },
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.enter,
        transform: Matrix4.identity()..translate(_offset.dx, _offset.dy)..rotateZ(_offset.dx * .0007),
        child: widget.child,
      ),
    );
  }
}
```

This is a gesture shell only. In production, animate the card offscreen, await a real provider/backend result, and handle failure by restoring the card and showing an error. Do not mark the action complete before the API succeeds. Ensure velocity thresholds, cancellation, keyboard/semantics alternatives, and repeated swipes are tested.

## 5. Match celebration

Use two assigned sticker avatars, not photos. The match moment should last roughly 700–1000 ms and must be skippable. Haptics are optional and only occur when a confirmed match event arrives.

```dart
class MatchCelebration extends StatefulWidget {
  const MatchCelebration({super.key, required this.mySticker, required this.otherSticker, required this.onContinue});
  final String mySticker;
  final String otherSticker;
  final VoidCallback onContinue;

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.hero,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _text = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.42, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onContinue,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: context.reduceMotion ? 1 : _scale.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StickerAvatar(stickerId: widget.mySticker),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite_rounded),
                    const SizedBox(width: 12),
                    StickerAvatar(stickerId: widget.otherSticker),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Opacity(
                opacity: context.reduceMotion ? 1 : _text.value,
                child: const Text('It’s a match!'),
              ),
            ],
          ),
        ),
      );
}
```

Replace `StickerAvatar` and icon styling with the actual app components and tokens. Do not use this widget to invent a match; call it only from the confirmed match state.

## 6. Page transitions

Keep transitions quick and consistent. Onboarding may use a fade/scale-in, discovery-to-match can use a short card transition, chat opens with a subtle shared-axis/fade, and sheets slide up. Respect reduced motion with a short fade or no transition. If using `go_router` custom pages, keep existing route names and extras unchanged unless separately approved.

## 7. Chat bubble entrance and grouping

Animate only newly received message IDs; never replay the entrance on every rebuild or scroll. Clear the seen-ID set when a new ephemeral chat starts.

```dart
final _seenMessageIds = <String>{};

Widget buildMessage(ChatMessage message, {required bool groupedWithNext}) {
  final isNew = _seenMessageIds.add(message.id);
  final bubble = ChatBubble(message: message, showTail: !groupedWithNext);
  if (!isNew || context.reduceMotion) return bubble;

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOutCubic,
    builder: (_, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(message.isMine ? 10 * (1 - value) : -10 * (1 - value), 8 * (1 - value)),
        child: child,
      ),
    ),
    child: bubble,
  );
}
```

Group consecutive messages by sender and a sensible short time gap. Do not show timestamps on every bubble. If timestamps are displayed, they apply to the active in-memory session only. Clear chat state at the actual end of the ephemeral session.

## 8. Typing indicator

Only show typing dots if the current backend emits an actual typing event and the client subscribes to it. Do not add a client-only fake typing state. Use three small dots with a subtle vertical wave and stop the controller when the chat is inactive or reduced motion is enabled.

## 9. Double-tap Next/Skip

If a single tap would irreversibly end the ephemeral conversation, require a deliberate confirmation. First tap changes the label to “Tap again to leave” and starts a short 1.5–2.0 s confirmation window; second tap executes the existing leave/skip action. Timeout resets the control. Announce the changing state via semantics and include a visible alternative that works for assistive technology. Never invoke the backend twice.

## 10. Toasts and skeletons

Use a small overlay toast or inline message instead of flooding the UI with SnackBars. Variants: neutral, success, warning, danger. Each variant must include icon plus text, not colour alone. Use toast only for transient status; validation and safety warnings should remain visible until resolved.

Skeletons should match the shape of the content being loaded (avatar + two text bars for a row, profile card for a discovery card). Use a low-contrast shimmer only when motion is allowed; otherwise use a static tinted surface. Do not simulate private message previews in skeletons.

## 11. Debug screenshot switch

Preserve screenshot protection in release builds. Use the debug define only for intentional design capture:

```dart
const allowScreenshots = bool.fromEnvironment('ALLOW_SCREENSHOTS');

// main.dart: keep the existing ScreenProtector initialization and error handling.
if (!allowScreenshots) {
  try {
    await ScreenProtector.preventScreenshotOn();
  } catch (error) {
    debugPrint('Screenshot protection could not be enabled: $error');
  }
}
```

Run a local design build with `flutter run --dart-define=ALLOW_SCREENSHOTS=true`. Never set this in release builds or CI release pipelines.
