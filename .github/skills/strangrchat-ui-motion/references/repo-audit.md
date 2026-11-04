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


## 8. New product and visual requirements supplied on 4 Nov 2026

The following are product/design decisions from the user and screenshot review, not claims that the repository already implements them. Re-check the current branch and backend before coding.

- **Visual reference:** editorial “stranger lounge” structure: warm paper canvas, large expressive serif headlines, restrained sans-serif navigation/body, thin separators, spacious page layouts, simple strong actions, horizontally separated friend rows, three-tier subscription comparison, clean profile settings, and a right-side notifications inbox on wide layouts. Apply the approved Milky Sage theme (warm off-white, milky surfaces, muted sage, deep forest actions) rather than copying the screenshot's sample brand.
- **Notifications:** add a top-bar notification bell and an inbox covering real product events, especially new friend requests and new message requests. The screenshot also shows match, subscription/trial, friend-saved, and chat-expiry notice patterns; show these only if those event sources exist. Confirm unread/read state, mark-all-read, push delivery, and route contracts before promising these actions. Never expose private chat message text in notification previews.
- **Country filter:** remove distance/radius/nearby matching and replace it with a Same country preference. The current audit identified a city plus radius UI; re-check whether it still exists. Country matching must be server-enforced using a trusted country value; do not request GPS or show precise location.
- **Female gender filter:** the Female match filter is intended to have three free uses and require subscription afterward. Reset cadence and when a use is consumed were not specified. Do not invent either; use a server-owned remaining-use/entitlement value or request the missing backend contract.
- **Sticker identity:** every new profile should receive a random goofy app-owned sticker instead of a real-person profile photo. Assign it once and keep its sticker ID stable across the app; do not reroll it on rebuild. The sticker asset key is profile metadata, distinct from ephemeral chat media. Remove profile-photo affordances, but do not remove image support used for ephemeral chat unless separately requested.

The five screenshots are visual references only: do not copy the “Kindred” wordmark, human portraits, sample people/messages, or displayed dollar prices. Keep StrangrChat branding and actual product/store data.
