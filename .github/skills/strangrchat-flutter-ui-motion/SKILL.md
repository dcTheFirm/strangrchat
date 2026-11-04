---
name: strangrchat-ui-motion
description: Redesign and build the UI/UX of the strangrchat Flutter app (anonymous, zero-storage random chat for India, Android and iOS) into a modern, distinctive, premium product with polished, purposeful motion. Use this skill for ANY change to strangrchat_app screens, theme, typography, colour, motion, navigation, chat bubbles, matching/searching states, report/block flows, friends list, VIP paywall, onboarding, loading/empty/error states, or when the user says the UI looks basic, generic, AI-made, or "sloppy". Use it even if the request is small (one widget), so the design system stays consistent.
---

# strangrchat UI + Motion

This skill is written for the existing codebase in `strangrchat_app/lib` (Flutter, Riverpod, go_router, Material 3). It was built after reading the code, so the rules below fix specific problems that exist today. Read `references/repo-audit.md` for the evidence (file and line pointers) and `references/motion-recipes.md` before writing animation code.

## 0. Hard constraints (never break these while redesigning)

The product promise is privacy and safety. UI work must not weaken either.

1. **UI only.** Do not change socket event names, payloads, API contracts, or server-authority rules. The client has no authority; never move enforcement (VIP, gender filter, limits) into UI logic.
2. **Zero persistence.** Never cache, save, or log chat text or images to disk or to any analytics. No `cached_network_image`-style disk caches for chat media. No remote Lottie/Rive URLs. No analytics or crash SDK that captures screens.
3. **No runtime font downloads.** A privacy-first app must not contact Google Fonts at launch. Bundle fonts as assets (no `google_fonts` runtime fetching).
4. **Keep safety features:** `ScreenProtector` (FLAG_SECURE), profanity filter, image guard, explicit 18+ and terms consent (never pre-checked), report/block. Make them better-looking and faster to reach, never optional. Add a `--dart-define=ALLOW_SCREENSHOTS=true` debug path so designers can capture screens; default is protected.
5. **Honest UI.** Do not show success the app did not achieve (see audit: "Friend request sent" snackbar fires without sending). Show pending, accepted, failed as real states.

## 1. Why the current UI feels "basic and AI-made" (diagnosis)

Findings from the 4 Nov 2026 repository snapshot (details in `references/repo-audit.md`); re-check before treating them as current:

- Zero animation: no `AnimationController`, `Hero`, implicit animation, or custom page transition anywhere. Only the chat auto-scroll animates.
- Only a light theme. No dark theme.
- Default Roboto everywhere; the text theme only sets weight and colour, so every heading is the same bold. No size scale, no tracking, no hierarchy.
- Hardcoded `TextStyle`, colours, radii and spacing in every screen. No design tokens, so nothing feels intentional.
- Stock Material widgets almost unstyled: `ChoiceChip`, `CheckboxListTile`, `Slider`, `DropdownButton`, `NavigationBar`, extended FAB, `AlertDialog`, `SnackBar`, `PopupMenuButton`, `CircularProgressIndicator`.
- The "AI template" tells: an icon inside a pale tinted circle used as logo and hero on three screens (onboarding, empty friends, paywall), identical bold 18 px section titles, uniform 12-16 px radii, generic marketing copy ("Anonymous, zero-storage real-time connections").
- Accessibility: white text on the brand coral (#FF6B61) is 2.79:1 contrast (needs 4.5:1), and coral icons on the ivory background are 2.67:1. This affects buttons and your own chat bubbles. The error colour is set equal to the brand colour, so errors and brand look the same.
- The home screen is one long form (intent, gender, city, radius, hobbies) and the main action is a floating button hidden below it.

## 2. Design direction (decisions, with reasons)

These are opinionated choices. Change them only deliberately.

**D1. Concept: "Milky Sage". Calm, warm, organic, and temporary.** Use a warm off-white canvas, milky white surfaces, muted sage accents, and deep forest-green actions. The product's privacy promise should appear in the experience through clear copy and a gentle chat-end dissolve—not through flames, sparks, neon glows, or loud effects. The result should feel premium, quiet, and human rather than clinical or template-driven.

**D2. Light-first, dark supported.** The approved visual direction is light and milky. Make the light theme the primary design reference, with a coherent dark theme available through the system setting. Do not make the dark theme the default or let it pull the light theme toward a black/green aesthetic. This is a design direction, not a claim about current implementation.

**D3. Sage is the brand accent; forest green is the action colour.** Use muted sage for selected states, illustrations, and gentle emphasis; use a sufficiently dark forest green for primary buttons, links, and important controls. Keep danger separate (deep red), success separate (deep green), and neutral surfaces quiet. Avoid coral, plum, neon green, and high-saturation gradients.

**D4. Type pairing (bundled).** Display: Bricolage Grotesque (characterful, modern). UI and chat text: Figtree (friendly, very legible). Add a Devanagari fallback (Noto Sans Devanagari) in the font family fallback list for future Hindi. [Verify licence files before bundling.] Do not use Roboto, Inter, or system default for headlines.

**D5. The Orb is the signature object.** One soft sage orb is the start-matching control on Home, becomes the radar centre while searching, and resolves into the two-avatar meeting at match. Keep its surface dimensional but restrained: a soft sage gradient and a faint ambient halo, never a bright neon glow. Continuity of one object across three states is what makes it feel crafted.

**D6. Safety is a first-class, beautiful surface.** Report and block live in a bottom sheet reachable from a visible shield button, not a hidden three-dot menu plus dialogs.

**D7. Motion quality tiers.** The audience is India on Android with many mid and low-range phones. Build effects in three tiers (full, lite, minimal) and drop automatically if frames are slow.

## 3. Design tokens (define once in `lib/app/tokens.dart` and `theme.dart`)

Never hardcode colour, radius, spacing, duration, or curve in a screen.

### Colour (contrast ratios computed, WCAG 2.x)

| Token | Light (primary) | Dark (supporting) | Notes |
|---|---|---|---|
| bg | #F7F8F3 | #17221B | warm milky page background |
| surface | #FFFFFF | #202D24 | cards, sheets |
| surfaceHigh | #EEF2EC | #2A392F | received bubbles, inputs, quiet panels |
| outline | #D8E1D7 | #3B4C40 | subtle hairlines; decorative only |
| outlineStrong | #7A8F7D | #728777 | visible control boundaries; check 3:1 against adjacent surfaces |
| text | #1E2B22 | #F1F4EE | primary text |
| textMuted | #56645A | #B5C1B5 | secondary text |
| forest | #355E45 | #A8C5AA | primary action and strong brand text in light theme |
| onForest | #FFFFFF | #17221B | text/icons on forest fills; verify contrast in both themes |
| sage | #7E9C80 | #9BB99C | selected states, icons, restrained emphasis |
| sageSoft | #DCE8DA | #34483A | soft selected surfaces and illustration fills |
| success | #286747 | #8BC39B | success; distinct from primary action when needed |
| danger | #B4233A | #F08A9B | report/destructive state; always pair with icon and label |

Rules: in the light theme, primary buttons and own chat bubbles use deep forest green (`forest`) with white `onForest` text; the sample pairing is approximately 7.4:1. Keep ordinary body text at 4.5:1 or better and meaningful component boundaries at 3:1 or better. The `outline` token is decorative and is not sufficient by itself to define an interactive control; use `outlineStrong` where a visible boundary is required. Use gradients sparingly: the Orb may use a soft sage gradient; primary buttons, chat bubbles, cards, and general backgrounds should stay flat. The dark theme must be contrast-tested independently.

### Type scale (Figtree for UI, Bricolage Grotesque for display)

- display: Bricolage 40/44, weight 700, tracking -1.0
- title: Bricolage 24/30, weight 600, tracking -0.4
- heading: Figtree 18/24, weight 700
- body: Figtree 16/24, weight 400 (chat text 16/22)
- label: Figtree 13/16, weight 600, tracking +0.2
- caption: Figtree 12/16, weight 500, muted colour

Respect dynamic type (test at 200%). No fixed-height containers around text.

### Shape, space, elevation

- Radii: 12 (chips), 20 (cards, inputs), 28 (sheets, bubbles), full (buttons, orb). Bubbles: 22 with a 6 radius on the tail corner.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48.
- Elevation: avoid stacked shadows. Use a 1 px `outline` hairline for quiet decoration and a very soft sage halo (8-14% alpha, blur 20-24) only on active or hero elements.
- Glass/blur: only on one small element at a time (floating nav). Blur is costly on low-end GPUs.

### Motion tokens

- fast 120 ms, base 220 ms, slow 380 ms, hero 900 ms.
- Entrances `easeOutCubic`, exits `easeInCubic`, moves `easeInOutCubicEmphasized`.
- Touch-driven motion uses springs (stiffness 400, damping 28 snappy; damping 18 for playful).
- Reduced motion: `MediaQuery.disableAnimationsOf(context)` true means: no loops, no parallax, no particles, crossfades only. Provide a Settings toggle as well.

### Milky Sage visual guardrails

- Page canvas: warm off-white, never pure grey or stark clinical white. Cards and sheets: milky white with quiet borders.
- Accent: muted sage. Primary action: deep forest green with accessible white text. Use forest green consistently for primary actions, not a bright or lime green.
- Keep shadows soft and sparse; use a subtle sage halo only for the Orb or one active hero element. No glass-heavy UI, glossy effects, neon, coral, plum, or large gradient backgrounds.
- The Orb may carry the only prominent soft gradient. Buttons, message bubbles, and ordinary cards are flat surfaces.
- Received message bubbles use the quiet surface colour. Sent message bubbles use forest green with white text. Verify both in light and dark themes.
- Error and report states use a distinct danger token and an icon plus label. Do not rely on colour alone.
- Preserve visual breathing room and varied hierarchy. Premium comes from typography, spacing, restraint, and motion—not from adding decorative effects.

## 4. Global patterns (apply everywhere)

- **Theme:** `AppTheme.light` is the primary Milky Sage reference; `AppTheme.dark` is the supporting counterpart. Generate both from explicit tokens and set `ColorScheme` explicitly (do not rely on `fromSeed` to pick surfaces). Map `forest` to `ColorScheme.primary` and `onForest` to `ColorScheme.onPrimary`. Use `themeMode: ThemeMode.system`.
- **Shared widgets** to build first, then reuse: `SageButton` (flat forest-green primary, spring press, loading morph), `GhostButton`, `PressableScale`, `AppChip` (replaces `ChoiceChip`), `AppToggleRow` (replaces `CheckboxListTile`), `AppSheet` (bottom sheet shell), `Toast` overlay (replaces `SnackBar`), `Orb`, `AvatarOrb` (generated avatar), `SkeletonBox`.
- **Page transitions:** custom `CustomTransitionPage` in the router. Onboarding to Home: fade-through. Home to Chat: circular reveal from the Orb. Paywall: slide up as a modal sheet-style page. Use the official `animations` package (`FadeThroughTransition`, `SharedAxisTransition`) where it fits.
- **Dialogs become sheets.** Report, block, remove friend, VIP teaser: bottom sheets with drag handle and spring.
- **Snackbars become toasts:** a top pill that springs in and auto-dismisses, with icon and semantic colour.
- **Haptics:** `selectionClick` for chip and toggle changes, `lightImpact` for taps, `mediumImpact` for starting a match, a two-beat pattern at match found, `heavyImpact` never. Provide a settings toggle.
- **Skeletons** for any async list. No bare spinners in content areas; spinner only inside a button while it morphs.
- **Every screen** implements: loading, empty, error/offline, and success states.
- **Semantics:** label every icon-only button and every animated state change (for example announce "Connected to a stranger", "Chat ended").

## 5. Screen blueprints (mapped to the real screens)

### 5.1 Onboarding (`onboarding_screen.dart`)

Goal: a brand moment plus meaningful consent, in at most 3 steps.

1. **Welcome (1.2 s moment, then idle):** Milky Sage mark (custom painter, not an icon-in-circle) draws in, the wordmark "strangrchat" in Bricolage rises with letters staggered 25 ms, a soft sage tint sits quietly in the background. Tagline in plain words, for example: "Talk to someone new. Nothing is saved." Replace the jargon line.
2. **How it works (skippable):** 3 swipeable cards with tiny looping illustrations: "Anonymous" (two orbs, no faces), "Nothing is stored" (bubbles that dissolve), "You're in control" (skip and report one tap). Page indicator is a stretching pill.
3. **Consent:** two `AppToggleRow`s (18+ confirmation; terms and zero tolerance), unchecked by default, each with a short, human sentence and a "Read terms" link. The "Enter" button is disabled until both are on, and animates from a muted surface to forest-green fill when enabled, with a haptic tick. Keep the anonymous session bootstrap in `initState` exactly as it is.

### 5.2 Home / Smart Match (`home_screen.dart`) (biggest change)

Today: a long scrolling form with a hidden FAB. Target: **the action first, filters on demand.**

- **Hero zone (top 60%):** the Orb, centred, with a one-line context above ("Ready when you are") and the active filter summary below as a tappable pill ("Friends · Anyone · Nearby"). The Orb breathes (scale 1.0 to 1.04, 4 s) with a faint sage halo; tapping compresses it with a spring and a medium haptic.
- **Intent selector:** a horizontally scrolling segmented control for Friends, Relationship, Married, Life Tips with a sliding highlight pill (one `AnimatedAlign` or custom painter), not four stock chips.
- **Match settings sheet** (opens from the summary pill): gender, city, radius, hobbies. Locked VIP options show a small sage lock and, on tap, open a one-screen VIP teaser on a quiet milky surface (short animation plus "See VIP") instead of jumping straight to the paywall. Radius uses a custom slider with a live value bubble and haptic ticks. Hobbies are `AppChip`s with a spring pop on select.
- **Navigation:** a floating pill nav with two destinations (Match, Friends) and a sliding indicator. The Friends tab shows a presence dot (animated pulse when a friend is online) and a badge for pending requests. Remove the app bar title and the snackbar on the shield; replace the shield with a "Safety" entry in the settings sheet.
- **VIP nudge:** a slim card that appears once per session with a shimmer, dismissible; never blocks the Orb.

### 5.3 Searching state (inside `chat_screen.dart`)

Today: a `CircularProgressIndicator` in a pale circle. Target: waiting that feels alive.

- The Orb moves to the centre and emits three expanding ripple rings (painter, 2.4 s loop). Faint dots drift in the ripples to imply others nearby (no fake counts).
- Rotating copy every 2.5 s, cross-faded: "Finding someone for you...", "Checking your filters...", "Almost there...". After 20 s show a gentle card: "Taking a while. Try Anyone or Nearby?" with a one-tap action.
- A visible "Cancel" ghost button at the bottom. Connection errors show an inline toast with Retry, never a dead screen.

### 5.4 Match found

Sequence 1.4 s, skippable by tap, then auto-settle into chat:

1. Ripples collapse to the centre (150 ms).
2. Two AvatarOrbs (yours and the stranger's, generated colours, no faces) slide in from the sides with a spring and meet with a brief, soft sage halo; success haptic pattern at contact.
3. Text fades up: "Connected" plus the intent chip ("Looking for: Friends") so expectations are set.
4. The orbs shrink into the chat header avatar position (shared-element feel), and the composer rises from the bottom.

### 5.5 Chat (`chat_screen.dart`)

- **Header:** AvatarOrb (generated from the room id, never stored), the name "Stranger", a live presence dot, **Add friend** (icon with real states: idle, pending, accepted, with a tiny morph), a **Safety** shield button that opens the report/block sheet. Remove the Skip text button from the app bar.
- **Skip lives in the thumb zone:** a capsule "Next" above the composer (left). Because chats are unrecoverable, skipping needs a deliberate second tap: first tap morphs it to "Tap again to skip" with a 1.8 s ring countdown, then skips. Haptic on each step.
- **Bubbles:** them = `surfaceHigh`, me = forest-green fill with `onForest` text. Radius 22 with a 6 tail corner. New bubbles rise 12 px and fade in with a spring (only newly arrived ones, not rebuilt ones). Group consecutive messages (tighter spacing, tail only on the last). Show a time label on tap or grouped every few minutes, not on each bubble.
- **Typing indicator:** the three-dot wave (if the server event exists; do not invent events, ask first).
- **Images:** 20-radius rounded image with a blur-up placeholder, tap opens a full-screen viewer with a Hero and pinch zoom. Keep images in memory (`Image.memory`); do not persist.
- **Composer:** pill input on `surfaceHigh`, image button left, send button right that morphs between disabled (muted) and active (forest green) and plays a quick "launch" animation on send. Profanity warning appears inline above the composer (shake plus danger tint), not as a red snackbar.
- **Keyboard:** the composer rises with the keyboard without layout jumps. Auto-scroll only if the user is near the bottom; otherwise show a "New messages" pill.
- **Chat ended / partner left:** do **not** leave the empty chat with "Searching..." in the title (current behaviour). Show an end card: the bubbles fade and drift upward gently (staggered from last to first, with no particle layer), then a calm panel: "Chat ended. Nothing was saved." with two actions: "Find next" (primary) and "Add friend" if still possible.
- **Model the states explicitly** (UI-facing, no server change): `idle`, `searching`, `matched`, `partnerLeft`, `error`, so each has its own designed screen. See audit for the current gap.

### 5.6 Report and block sheet

- Opened from the Safety shield. Large rows with icons: "Report" (opens reason chips: Harassment, Sexual content, Spam or scam, Underage, Other; the schema has a `reason` column but no report endpoint exists yet, so agree the API with the backend owner first and until then do not claim a report was filed), "Block", "Just skip". Selection chips spring; a confirm button states exactly what will happen ("Report and find someone new").
- After confirm: a checkmark morph (400 ms), then automatic transition to searching so the user feels safe immediately. Tone: calm, never interrogating. Never use the brand sage/forest palette for danger; danger has its own colour and icon.

### 5.7 Friends (`friends_list_screen.dart`)

- Rows: AvatarOrb with online presence ring (pulse when online), name, "Connected 2h ago", primary action "Chat" and a swipe (spring-back) for Remove with an undo toast. Remove uses a sheet, not an `AlertDialog`.
- Empty state: an animated illustration (two orbs orbiting slowly), a human line, and a CTA to start matching. Not an icon in a pale circle.
- First-screen entrance: staggered fade and slide (40 ms offsets), run once.

### 5.8 VIP paywall (`vip_paywall_screen.dart`)

- Hero: a restrained sage illustration on a milky surface with a faint ambient halo and a floating orb cluster; headline in Bricolage ("Meet who you actually want to").
- Perks: four rows with small animated icons that play once on entry (staggered).
- Plans: two cards (48-hour pass, Monthly) with a **sliding selection highlight** (one shared animated border), price count-up on change, "Best value" ribbon. Keep real localised price from the store; fall back to rupee values as now.
- CTA: `SageButton` that morphs to a spinner while purchase starts, subtle, low-contrast shimmer every 6 s (once visible). Keep "Restore purchases" visible and the renewal terms text. No fake urgency, no hidden close button, no pre-selected expensive trap beyond what exists today.
- Success: a confetti-free celebration (brief sage halo from the CTA, 700 ms), toast, then close.

## 6. Build order (for agents)

1. Fonts, tokens, `AppTheme.dark/light`, `Motion`, `Haptics`, `MotionQuality`, reduced-motion helpers.
2. Shared widgets (section 4), each with a golden or widget test and a reduced-motion path.
3. Router transitions, then Home plus Orb, then Searching, Match found, Chat, Chat ended, Report sheet.
4. Friends, Paywall, Onboarding.
5. Polish pass: dark and light, 200% text, TalkBack/VoiceOver, profile mode on a low-end Android phone.

For each screen deliver: widget code, all states, motion spec (duration, curve, trigger), haptics, semantics, and a note of anything that needs a backend decision.

## 7. Performance and quality gates

- Profile mode on a real low-end Android device. Target steady 60 fps (120 on capable displays); investigate frames above budget.
- One looping hero effect per screen. Wrap independent animations in `RepaintBoundary`; pass static `child` into `AnimatedBuilder`.
- `MotionQuality` tier (full, lite, minimal) chosen from measured frame timings in the first seconds and a user setting. Lite: fewer particles, no blur. Minimal: no loops, fades only.
- Avoid `Opacity` over large trees; avoid clip plus opacity on big areas; limit `BackdropFilter` to one small element.
- Decode images at display size; images stay in memory only.
- Dispose controllers and timers; guard async callbacks with `mounted`.

## 8. Review checklist (every PR)

- [ ] Uses tokens only; no hardcoded colours, sizes, durations
- [ ] Contrast: text 4.5:1, components 3:1 in both themes; no white on #FF6B61
- [ ] Dark and light verified; text scale 200% verified
- [ ] All states designed: idle, searching, matched, partnerLeft, error, offline, empty, loading
- [ ] Reduced-motion path works; haptics toggle respected
- [ ] No disk writes, no network fonts, no analytics of chat content
- [ ] Safety reachable in one tap on chat and searching screens; report has reasons
- [ ] Icon buttons have semantics and tooltips
- [ ] No "AI template" tells: no generic icon-in-tinted-circle heroes, no identical bold section titles, no generic marketing copy
- [ ] Profile mode on low-end Android holds frame rate

## 9. Anti-slop rules

- One strong idea per screen; resist decorating. If an element has no job, remove it.
- Vary rhythm: not every card the same radius and padding; not every title the same weight.
- Copy sounds like a person: short, warm, specific. English-first; light, respectful Hinglish only in micro-copy and only if consistent.
- No stock gradient blobs, no emoji as icons, no placeholder illustrations, no unmodified Material defaults.
- Prefer custom painters and a few well-made assets over many packages.
