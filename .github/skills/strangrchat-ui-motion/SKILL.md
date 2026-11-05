---
name: strangrchat-ui-motion
description: Design and implement StrangrChat's Flutter UI/UX in the playful Peach Pop visual system inspired by the bundled dating, matching, onboarding, and chat reference screenshots. Use for any change to onboarding, discovery/matching, swipe cards, match moments, chat list, chat, sticker avatars, friend/message requests, notifications, country/gender filters, profile, subscription, safety, navigation, typography, themes, motion, loading, empty, or error states. Apply even to small UI changes to keep the product coherent.
---

# StrangrChat UI/UX + Motion Skill

This skill targets the existing Flutter application in `strangrchat_app/` and its existing backend in `strangrchat_server/`. Start with `references/ui-reference-spec.md`, inspect the visual screenshots in `references/visuals/`, use `references/repo-audit.md` as a dated audit snapshot, and consult `references/motion-recipes.md` before adding animations. Optional free/open-source resources are listed in `references/free-ui-resources.md`.

**First step for every task:** inspect the current branch's relevant widgets, providers, routes, models, assets, tests, and backend contracts. The repo audit is dated 4 Nov 2026 and may be stale. Do not assume a screen, endpoint, socket event, counter, entitlement, or dependency still exists until verified.

## 0. Non-negotiable product and engineering rules

1. **Preserve StrangrChat, not a template app.** Keep the existing Flutter/Riverpod/go_router structure and the current Node.js/Socket.IO backend. Do not replace the backend with Firebase, Supabase, or another service. Do not transplant an entire sample app.
2. **Preserve anonymous and ephemeral chat.** Never persist, cache, or log chat text or chat images to disk or analytics. Do not add a disk-backed chat-media cache. Chat content remains in memory for the active session only and must be cleared when the session ends. Do not put private message text in local notifications, push payloads, analytics, crash logs, or notification inbox previews.
3. **Profile identity uses app-owned stickers.** Do not use profile-photo upload, gallery selection, camera capture, or actual user portraits. Assign one random goofy sticker illustration to each profile at creation, then keep the sticker ID stable across rebuilds, app launches, and devices. Store only the sticker asset key/ID as profile metadata if the existing contract supports it. Do not randomize on every render. Sticker identity is distinct from ephemeral chat image sharing, which must follow the existing safety and no-persistence rules.
4. **Server is authoritative.** The backend/store—not the client UI—owns matching eligibility, gender filters, the three-free-use allowance, same-country matching, queue priority, friend requests, report/block actions, notification delivery/read state, and subscription entitlements. UI may display authoritative state; it must not be the security boundary.
5. **No distance or radius matching.** Remove distance, radius, “nearby”, “X km away”, and GPS permission flows from matching. Use a Same country preference instead. Do not expose coordinates, city-level precision, or exact location in cards or notifications.
6. **Female filter allowance.** The Female gender-match filter has three free uses; further use requires the applicable subscription. The reset cadence and exact consumption point were not specified. Do not invent a daily/monthly/lifetime reset or decide whether opening the filter, starting a queue, or completing a match consumes a use. Read the backend contract or flag the missing decision. Never enforce this gate only in Flutter.
7. **Honest UI.** Never claim a friend request, message request, report, block, save, notification, or purchase succeeded unless the actual operation returns success. Represent idle, loading, pending, success, unavailable, and failure states truthfully.
8. **Keep safety and consent.** Preserve screenshot protection (`ScreenProtector`/FLAG_SECURE), profanity filtering, image guard, report/block access, explicit 18+ confirmation, and terms/zero-tolerance consent. Consent must remain unchecked by default. Improve the presentation; do not remove safeguards to simplify screens.
9. **No runtime font downloads.** Bundle font files and licence notices with the app. Do not use `google_fonts` in a way that downloads fonts at runtime.
10. **No invented contracts.** If notification inbox, push, same-country, friend/message request, sticker metadata, or gender-use quota support is missing, document the backend dependency and ask for/agree the contract before building a fake interaction.

## 1. Visual system: Peach Pop

The latest bundled screenshots are the primary visual reference. They supersede the older Milky Sage/editorial direction. Reproduce the screenshots' playful, modern dating-app energy while adapting details to StrangrChat's privacy model and sticker-only profile identity.

### Visual signature

- **Mood:** warm, playful, social, optimistic, expressive, and polished. It should feel like a consumer dating/discovery app, not a corporate dashboard or a generic Material sample.
- **Backdrop and hero moments:** use soft peach-to-pink-to-lavender gradients in onboarding, match celebrations, and large promotional/empty-state compositions. Do not put a loud gradient behind every page or every card.
- **App surfaces:** warm cream/off-white screens with white or softly tinted cards. Use subtle shadows, soft borders, and rounded corners. Keep content readable and avoid excessive glass/blur.
- **Primary action:** coral-to-tangerine gradient or accessible deep coral button, rounded/pill-like, with a clear label and tactile press response. For the brighter gradient, use dark ink text if white text cannot meet contrast.
- **Secondary accents:** soft blush, peach, muted lavender, warm sand, and small mint/green status accents.
- **Typography:** friendly geometric/rounded sans-serif for headings, body, buttons, and navigation. Use bold, short headlines and readable line lengths. Do not carry forward the previous large editorial serif system as the primary look.
- **Imagery:** replace people in the reference screenshots with original app-owned goofy sticker characters. Use a consistent illustration style, not emoji glyphs and not real-person photos.
- **Navigation:** compact top bar for brand/actions where needed and a dark, rounded bottom navigation capsule with a coral active state on main app screens, matching the supplied chat/discovery references.
- **Density:** mobile-first. Make the main action obvious, cards easy to scan, and chat controls reachable by thumb. Avoid overfilling the viewport.

### Starting colour tokens

Define colours centrally (for example `lib/app/tokens.dart`) and apply through the app theme. These are starting values, not unverified accessibility guarantees; calculate contrast for actual foreground/background pairings before shipping.

| Token | Starting value | Intended use |
|---|---:|---|
| `bg` | `#FFF8F4` | warm cream screen background |
| `surface` | `#FFFEFC` | primary cards, sheets, message list |
| `surfaceWarm` | `#FFF0E8` | incoming bubbles, search fields, soft panels |
| `peach` | `#FFD6C2` | illustration and onboarding tint |
| `blush` | `#F5C2D7` | soft selected/illustration accent |
| `lavender` | `#D8B3E5` | gradient and decorative accent |
| `coral` | `#F15B50` | bright brand accent, icon fills, gradient stop |
| `coralDeep` | `#B94336` | accessible coral button/text option |
| `tangerine` | `#FF913F` | gradient stop and warm accent |
| `ink` | `#211C1B` | main text, dark surfaces, button text on bright gradient |
| `muted` | `#786F6D` | secondary text and metadata |
| `line` | `#EDE3DE` | subtle separators and card borders |
| `navDark` | `#211C1B` | dark bottom navigation |
| `success` | `#187A58` | online/accepted states, always with text/icon |
| `danger` | `#B4233A` | report, block, destructive states |

A bright coral/tangerine gradient may be used with `ink` text when that maintains adequate contrast. If white text is required, use a sufficiently dark coral fill (for example `coralDeep`) and verify at least 4.5:1 for normal text. Body text must meet WCAG 2.x 4.5:1; meaningful controls/indicators should meet 3:1. Do not rely on colour alone for online, unread, selected, error, or subscription states. Dark mode must be designed and tested separately rather than simply inverting these values.

### Typography, shape, spacing

- Prefer a friendly display face such as bundled **Bricolage Grotesque** or **Manrope** for prominent titles, paired with **Figtree** for body, forms, navigation, and chat. Use only fonts actually bundled and declared in `pubspec.yaml`; verify licences and family names.
- Suggested scale: hero 34–42sp / heavy; page title 26–32sp / bold; section heading 18–22sp / bold; body 15–17sp; helper/metadata 11–13sp. Chat text should remain comfortable at 16sp where possible.
- Typical radii: 14–18 for inputs/chips, 20–28 for cards and sheets, full radius for primary CTA and bottom-nav capsule. Message bubbles may use 18–22 with a slight tail-like corner distinction.
- Spacing scale: 4, 8, 12, 16, 20, 24, 32. Use generous outer padding and consistent gaps.
- Shadows are soft and sparse. Avoid stacked shadows, hard neon glows, and excessive blur.
- Respect platform safe areas, keyboard insets, large text scaling, and narrow screens. Never fix a visual composition by clipping content.

## 2. Reference screens and required experience

Read the detailed visual interpretation in `references/ui-reference-spec.md`. The screenshots are design references only: never copy sample names, human photos, message text, prices, brand marks, or fake status data.

### 2.1 Onboarding

- Use a warm peach/pink/lavender backdrop or a cream screen with a controlled gradient hero panel.
- Feature an orbital composition of goofy sticker characters, tiny hearts, speech marks, and subtle dotted paths. Keep the illustration bespoke and balanced; do not use generic emoji as final artwork.
- Show a bold headline, one short explanation, one prominent “Find someone” / equivalent CTA, and compact pagination/progress markers if onboarding has multiple steps.
- Keep 18+ and terms/zero-tolerance consent explicit and unchecked by default. Do not hide consent behind a swipe gesture or decorative panel.

### 2.2 Home / discovery / matching

- Use a clear discovery hierarchy: top app bar, “New matches” or another truthful section, a horizontal strip of sticker avatars when real match data exists, and a large discovery card/primary matching action.
- The screenshot's “Near You” label and kilometre distance must not be copied. Use a neutral section label such as “Discover” or “Same country” only when that reflects a real filter/data source.
- Use assigned sticker characters in the hero/profile card. The sticker may be framed by a colourful panel or illustrated scene, with the display name/alias and approved non-sensitive details beneath it.
- If the existing product includes swipe mode, use a layered card stack with clear pass/like gestures, visible buttons for accessibility, and a match transition. If swipe mode is not implemented in the current app/backend, do not silently invent persistence, matching, or queue behavior; implement only the requested UI with explicit integration notes.
- The random-chat action should remain prominent and must connect to the existing queue flow. Do not bury it behind filters.
- Matching preferences should be in a compact sheet/secondary screen: gender, Same country, and any already-supported interests. No distance slider/radius picker.
- Female filter UI displays the remaining free-use count only from server state. After three free uses, show the actual subscription gate. Do not invent a reset time.

### 2.3 Match found

- Use the composition from the reference: celebratory headline, two large overlapping/adjacent profile visuals, and one short line explaining the connection.
- Both visuals must be the users' assigned goofy sticker illustrations, never photos.
- Use a short, joyful entrance animation (sticker rise/scale, small heart burst, text fade) and one strong “Say hello” action, plus a low-emphasis Later/Continue alternative where appropriate.
- Do not imply a persistent match if the server only created an ephemeral chat session. Copy must reflect the actual state (“Connected” vs “Match saved”).

### 2.4 Chat list / requests

- Use a warm cream screen with a rounded search field and clean rows: sticker avatar, display name/alias, latest safe metadata, time/status, and unread/request indicator.
- The supplied reference shows previews of message text. StrangrChat must not persist chat text, so do not reproduce persistent private-message snippets. Use safe metadata such as “New message request”, “Waiting for your reply”, or session state only if supported.
- Separate new friend requests and message requests from active/kept friends when real APIs/events support that split. Request actions must show pending/loading/success/failure states.
- Use a dark rounded bottom navigation with simple icons and a coral active state, adapted to existing destinations.

### 2.5 Chat conversation

- Keep header simple: back, assigned sticker avatar, alias, truthful online/connection state, and a compact menu or visible Safety action.
- Use warm neutral incoming bubbles and soft peach/blush outgoing bubbles; maintain strong text contrast. Bubbles should be rounded, grouped by sender, and animate only once on arrival.
- Keep composer anchored above the keyboard with an image/attachment action only if the existing ephemeral image pipeline supports it. Use a coral send action with disabled/enabled/loading states.
- Do not store chat history, persist media, show content from a previous ended chat, or place message previews in notifications.
- Keep Skip/Next deliberate when it ends an ephemeral conversation; use double-tap confirmation or an equivalent guard if supported by current behavior.
- Partner-left/chat-ended must have its own state. Never show an empty composer beneath a misleading “Searching…” label.

### 2.6 Notifications

- Put an accessible notification bell in the top bar, with a visible unread marker/count.
- Inbox types should include new friend request and new message request, plus only other event types verified in the app (for example a match event or subscription state). Do not invent events.
- Notifications must not reveal private chat text. Use wording like “You have a new message request”, not the message content.
- Wide layouts may use a right-side panel; phones should use a sheet or full-screen inbox.
- Mark read, mark all read, accept/decline, and routing are functional only if supported by the backend. Display unread/read, loading, empty, and error states.

### 2.7 Friends / kept connections

- Use sticker avatars, a short alias/display name, real presence/last-active data if available, and distinct actions to chat or remove.
- Do not show kilometres, nearby status, or city-level precision.
- Chat must actually route to the correct supported friend/conversation. Never use a route that just opens a generic chat and claim it started a friend chat.
- Remove uses a confirm/undo pattern with honest result feedback.

### 2.8 Profile

- Show the stable goofy sticker avatar as identity. No photo change/upload entry point.
- Profile fields (display name, bio) and preferences should use clear labels, rounded controls, and concise descriptions.
- Online status, read receipts, notifications, and other toggles must reflect actual persisted settings and backend capability.

### 2.9 Subscription / paywall

- Use the warm gradient/cream style with prominent plan cards. On wide layouts a three-column comparison can be used; on Android, stack the cards or use a clear segmented selector so there is no cramped horizontal overflow.
- Feature one plan with a darker or more saturated surface, but retain readable contrast and avoid fake urgency.
- Show store-localized prices, purchase progress, success/failure and Restore purchases. Do not copy dollar prices, plan names, trial periods, or benefits from reference screenshots.
- Explain the Female filter allowance accurately using real entitlement state. Do not claim a tier unlocks a feature until the store/backend confirms it.

### 2.10 Safety

- Safety/report/block remains reachable in one tap from active chat and relevant request/profile surfaces.
- Use a calm rounded sheet with clear reasons and destructive styling for report/block. Require confirmation for irreversible actions.
- No success snackbar or checkmark until backend confirmation. If no endpoint/event exists, document that dependency and do not fake it.

## 3. Shared Flutter components

Create reusable components before polishing each screen independently. Reuse current app architecture and naming conventions; these are conceptual names, not a requirement to create duplicate components if equivalents already exist.

- `PeachPopScaffold` / shared page shell
- `BrandGradientButton` (primary, secondary, disabled, loading)
- `StickerAvatar` (stable sticker key; no portrait fallback)
- `StickerOrbit` / `OnboardingOrbit`
- `DiscoveryCard` / `SwipeCard` (only when swipe feature exists)
- `MatchCelebration`
- `ChatListTile` / `RequestTile`
- `ChatBubble` and `ChatComposer`
- `NotificationBell` and `NotificationInbox`
- `BottomNavCapsule`
- `AppSheet`, `AppTextField`, `AppToggleRow`, `AppChip`
- `PresenceIndicator`, `Toast`, `SkeletonRow`, `SkeletonCard`

Define colours, type scale, radii, spacing, shadows, and motion tokens centrally. Avoid one-off hardcoded styling in feature screens. Use Material 3 as a foundation, not as the finished visual language.

## 4. Free UI kit / package rules

Consult `references/free-ui-resources.md` before choosing third-party UI. Prefer a small, licensed component/package for a single screen (for example chat bubbles) rather than importing a full dating app. Check the exact current package version, licence, compatibility with the repository's Dart/Flutter SDK, transitive dependencies, caching behavior, privacy impact, and accessibility before adding it.

A chat UI component must not introduce disk caching or persistent message history. Keep StrangrChat's Socket.IO/Node backend and current state-management approach. If a kit requires Firebase/Supabase, use it only as a visual reference unless the user explicitly asks to migrate.

## 5. Motion and interaction principles

- The visual style is playful, but animation should explain interaction: sticker orbit during onboarding/search, swipe/stack movement for discovery, two-sticker meet moment for match, bubble entrance for new messages, and a small spring response for buttons.
- Use one primary looping animation per screen at most. Never make every icon pulse.
- Respect `MediaQuery.disableAnimationsOf(context)`: disable loops, large transforms, parallax, and particles; replace with a short fade/static illustration.
- Haptics are optional feedback, not the only confirmation. Respect a user setting if one exists.
- Use small spring press feedback, smooth ease-out entrances, and short ease-in exits. Avoid long blocking animations; navigation and chat must feel responsive.
- Dispose controllers/timers and guard async callbacks with `mounted`.
- Profile on low-end Android devices. Avoid full-screen blur, expensive particle systems, nested opacity over large trees, and unnecessary rebuilds.

## 6. Build sequence for broad redesigns

1. Inspect current branch and verify the dated repo audit against the actual code.
2. Map routes/providers/events and identify backend dependencies before changing UI.
3. Add Peach Pop design tokens/theme and verify contrast; do not globally change behavior.
4. Build sticker assets/registry and stable avatar assignment without adding real-photo upload.
5. Build app navigation, notification bell, and inbox states.
6. Redesign onboarding and home/discovery; remove distance and wire Same country plus server-backed Female allowance.
7. Implement/refresh match-found, chat list/requests, active chat, and partner-left states.
8. Redesign friends, profile, subscription, and safety surfaces.
9. Run `dart format`, `flutter analyze`, relevant widget/unit tests, and manual Android checks for keyboard, safe areas, text scaling, reduced motion, and low-end performance.

For every screen, deliver: widget code, all real states (loading/empty/error/offline/success), responsive layout, animation/haptic spec, semantics, tests, and explicit backend gaps.

## 7. Pull request / implementation checklist

- [ ] Used the bundled screenshots and `ui-reference-spec.md` as visual references.
- [ ] Uses Peach Pop tokens; no old Milky Sage-only/serif editorial styling unless a specific component calls for it.
- [ ] Uses app-owned sticker art; no profile portraits, photo upload, or unstable random avatar changes.
- [ ] No distance/radius/nearby/GPS matching UI remains; Same country is server-backed.
- [ ] Female filter has three free uses; count and subscription decision are server/store authoritative; reset/consumption semantics are not invented.
- [ ] Notification bell and inbox are wired only to real events; no private message previews.
- [ ] Existing Node.js/Socket.IO, Riverpod, go_router, and API contracts are preserved.
- [ ] Chat text and images remain ephemeral and are not written to persistent caches/logs/analytics.
- [ ] No false friend/request/report/block/save/purchase success states.
- [ ] Safety is reachable; 18+ and terms consent remain explicit and unchecked by default.
- [ ] Contrast, semantics, keyboard/focus, reduced motion, and 200% text scale verified.
- [ ] `flutter analyze` and relevant tests pass; low-end Android performance checked.

## 8. Anti-template rules

- Do not reproduce the screenshots pixel-for-pixel or copy their brand, profile photos, names, messages, prices, icons, or assets.
- Do not turn every surface into the same card. Vary hierarchy and use whitespace intentionally.
- Avoid generic emoji avatars; use a designed sticker pack with a coherent art direction.
- Avoid random gradient blobs, excessive shadows, constant shimmer, and stock Material defaults.
- Never fake matching, request, notification, friend, report, block, or subscription behavior.
- Keep copy short, warm, playful, and honest. Privacy and safety claims must match the actual implementation.
