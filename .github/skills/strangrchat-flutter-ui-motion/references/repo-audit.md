# strangrchat repo audit (UI/UX focus)

Snapshot of `github.com/dcTheFirm/strangrchat` as cloned on 4 Nov 2026 (default branch, depth 1). Line numbers will drift; search by the quoted code. Re-run the checks before relying on them.

## Contents
1. Styling and theme
2. Motion
3. Screen-level UX issues
4. State and honesty gaps that hurt polish
5. Accessibility
6. Privacy items worth a look (not UI, but they touch the brand promise)
7. Dependencies

## 1. Styling and theme

| Finding | Where | Why it matters |
|---|---|---|
| Only `AppTheme.lightTheme`; no `darkTheme`, no `themeMode` | `main.dart:28`, `app/theme.dart` | No dark mode; flat look |
| No custom fonts; `pubspec.yaml` has no `fonts:` section | `pubspec.yaml` | Default Roboto reads generic |
| Text theme sets only weight and colour, no size/tracking/family | `app/theme.dart` (`textTheme`) | No typographic hierarchy |
| `error: primaryCoral` makes error colour equal to brand | `app/theme.dart:24` | Errors indistinguishable from brand accents |
| Hardcoded `TextStyle(fontSize: ...)`, colours, radii across screens | all `features/*` | No design tokens, inconsistent rhythm |
| Same pale `softBlush` circle with an icon used as logo/hero | `onboarding_screen.dart:58`, `friends_list_screen.dart:89`, `vip_paywall_screen.dart:96` | The classic "AI template" tell |
| Stock widgets with minimal styling | `home_screen.dart` (ChoiceChip lines 114, 170, 179; DropdownButton 134; Slider 152; NavigationBar 69; FAB 54), `onboarding_screen.dart` (CheckboxListTile 97, 120) | Looks like the Material demo |

## 2. Motion

- No `AnimationController`, `AnimatedContainer`, `AnimatedSwitcher`, `Hero`, `TweenAnimationBuilder`, or custom `CustomTransitionPage` anywhere in `lib/`.
- The only animation is `_scrollController.animateTo` in `chat_screen.dart` (`_scrollToBottom`).
- `go_router` routes use plain `builder:` so every navigation uses the platform default transition.
- No haptics (`HapticFeedback`) anywhere.
- Loading states are `CircularProgressIndicator` (`chat_screen.dart:251`, `vip_paywall_screen.dart:128,135`).

## 3. Screen-level UX issues

**Home (`home_screen.dart`)**
- `_SmartMatchView` is a single scroll of five sections (intent, gender, city plus radius, hobbies, VIP nudge). The primary action is an extended FAB at the bottom (line 54), easy to miss below a long form.
- Locked options immediately push `/vip` (`context.push('/vip')` in gender and city handlers), which feels like a trap rather than a preview.
- The shield button only shows a snackbar ("Zero-Storage & Safety Protection Enabled"), no real destination.

**Chat (`chat_screen.dart`)**
- App bar holds a status dot, title, Add friend icon, Skip text button, and overflow menu: five competing items.
- Report and Block hide behind `PopupMenuButton` (line 205) then `AlertDialog` (lines 100, 132). Report collects no reason although the backend schema has `reason`.
- Skip is one tap in the app bar with no protection, but chats are unrecoverable (zero storage), so accidental skips lose the conversation.
- Message bubbles appear with no entrance motion; no grouping; no timestamps displayed although `ChatMessage.timestamp` exists; images are fixed 200x200 with no viewer.
- Profanity and image errors use red `SnackBar`s.

**Friends (`friends_list_screen.dart`)**
- "Chat Now" calls `context.push('/chat')` (line 59), which opens the chat screen but does not start a chat with that friend (UI implies it does).
- Names render as "Stranger #id" with the same avatar treatment for everyone.

**Paywall (`vip_paywall_screen.dart`)**
- Static layout; plan selection only changes a border; no motion; icon-in-circle hero.
- Strengths worth keeping: store price with rupee fallback, Restore purchases, renewal terms text, `Semantics` on plan cards.

**Onboarding (`onboarding_screen.dart`)**
- Two checkboxes plus a button; no brand moment. Copy "Anonymous, zero-storage real-time connections." is jargon.
- Strengths worth keeping: consent not pre-checked; silent anonymous session bootstrap in `initState`.

## 4. State and honesty gaps that hurt polish

- `chat_provider.dart` `_resetAfterPartnerLeft` (line 191-193) sets `state = const ChatState()`: not searching, not connected. In `chat_screen.dart` the title then shows "Searching..." (line 177) while the body shows an empty chat with a composer. The UI has no "chat ended" state. Recommend an explicit UI-facing status (`idle`, `searching`, `matched`, `partnerLeft`, `error`).
- `joinQueue` failures `rethrow` after resetting state; the home FAB wraps it in `unawaited(...)` and navigates to `/chat` immediately, so errors have no designed surface.
- Add friend shows "Friend request sent to partner!" (`chat_screen.dart:190`) without calling any provider or socket event. The user is told something happened that did not. Wire real states (idle, pending, accepted) or hide the button until the backend is ready.
- Report and Block in the chat screen only call `skipPartner()`. A search of the Flutter `lib/` and of `strangrchat_server/src` found no report or block request or handler (the Prisma schema has a `ModerationReport` table, but nothing writes to it yet). The snackbars claiming "Report submitted" and "User blocked" therefore promise more than the code does. The redesigned report sheet needs a backend endpoint or socket event first; until then, label it honestly or gate it behind the backend work.

## 5. Accessibility

- Contrast (computed): white on `#FF6B61` = 2.79:1 (buttons, own bubbles); `#FF6B61` on `#FFF9F5` = 2.67:1 (icons, links). Both fail WCAG (4.5:1 text, 3:1 components).
- Only one `Semantics` widget in the whole app (plan cards). Icon buttons rely on tooltips only in some places.
- No reduced-motion handling (not needed today, because there is no motion; required once motion is added).
- Text uses fixed font sizes; verify at 200% text scale.

## 6. Privacy items worth a look (not UI, but they touch the brand promise)

- `core/safety/image_guard.dart` writes compressed images to `getTemporaryDirectory()` as `compressed_<timestamp>.jpg` (lines 11-14) and nothing deletes them. The app promises no images on disk; temp files persist until the OS clears cache. Consider deleting after send and avoiding file-backed message images (`ChatMessage.imageFile`).
- `ImageGuard.isImageSafe` is a placeholder that returns `true` (line 35-38). UI copy must not claim NSFW protection until a real model is in.
- `ProfanityFilter` is a small exact-word list; leetspeak and spacing bypass it. Treat as a first line, not a promise.
- `ScreenProtector.preventScreenshotOn()` is global in `main.dart:12`. It also blocks your own design screenshots; add a debug define to disable it during design review.

## 7. Dependencies (from `pubspec.yaml`)

Present: `flutter_riverpod ^3.4.3`, `go_router ^18.1.2`, `dio`, `socket_io_client`, `flutter_secure_storage`, `flutter_image_compress`, `image_picker`, `path_provider`, `in_app_purchase`, `screen_protector 1.5.1`.

Absent (suggest adding, verifying current versions on pub.dev): `flutter_animate`, `animations` (official transitions), optional `lottie` (bundled assets only) or `rive` for one signature illustration. Fonts are bundled assets, not a package.


## 8. Approved visual direction: Milky Sage (design target)

This section records the approved direction for future UI work. It is a design target, not evidence that the Flutter implementation has already changed. The findings above remain a snapshot of the repository cloned on 4 Nov 2026; re-run the checks before relying on them.

- **Overall feel:** premium, calm, organic, minimal, light, and milky.
- **Canvas and surfaces:** warm off-white page background; milky white cards and sheets; subtle sage-tinted borders.
- **Accent and actions:** muted sage for selected states and illustration details; deep forest green for primary buttons, sent chat bubbles, and high-priority actions.
- **Orb:** soft sage gradient with a faint ambient halo; no coral, plum, neon, or loud glow.
- **Typography:** retain the bundled Bricolage Grotesque display / Figtree UI pairing proposed in the skill, subject to font licence and asset verification.
- **Motion:** preserve the existing motion recipes, but tune them to feel soft and purposeful. Prefer restrained breathing, gentle ripple rings, spring press feedback, and a calm chat-end fade. Do not add decorative particles or constant motion without a clear purpose.
- **Surface discipline:** keep buttons, cards, and chat bubbles mostly flat. Reserve the most dimensional treatment for the Orb and its match transition.
- **Accessibility:** use deep forest green with white text for light-theme primary actions; test all foreground/background pairs at implementation time. Use a stronger outline for interactive boundaries where needed, and keep danger visually distinct from brand/success.
- **Theme:** light-first. A matching dark theme may be supported, but it must not dilute the approved light, milky visual direction.

The `#FF6B61` contrast measurements and coral/error-colour findings in section 5 refer only to the historical repository snapshot above; they are not Milky Sage tokens.
