---
name: strangrchat-ui-motion
description: Design and implement StrangrChat Flutter UI/UX using the Milky Sage editorial lounge system. Use for any change to onboarding, home/matching, gender or country filters, chat, friend requests, kept friends, notifications, profile, subscriptions, stickers/avatars, safety, navigation, typography, themes, motion, loading, empty or error states. Apply this skill even for small UI changes so the product remains coherent.
---

# StrangrChat UI, UX + Motion Skill

This skill targets the existing Flutter app in `strangrchat_app/` (Riverpod, go_router, Material 3) and its existing backend in `strangrchat_server/`. Read `references/ui-reference-spec.md` for the supplied visual references and product requirements, `references/repo-audit.md` for the 4 Nov 2026 code snapshot, and `references/motion-recipes.md` before writing animation code.

**First step for every task:** inspect the relevant current widgets, providers, routes, models, and backend contracts. The audit is a dated snapshot, not proof that code is unchanged. Do not assume a screen, endpoint, event, counter, or entitlement exists until verified in the current branch.

## 0. Product and implementation guardrails

1. **Preserve the product promise.** StrangrChat is anonymous, ephemeral random chat. Do not weaken privacy, consent, reporting, blocking, or age requirements to make a screen look simpler.
2. **Do not silently change contracts.** Preserve socket event names, payloads, REST contracts, Prisma schema semantics, server authority, and navigation behavior unless the user explicitly requests a product/backend change. Flag missing backend support instead of inventing an API or pretending a UI control works.
3. **Keep chat ephemeral.** Never persist, cache, or log chat text or chat images to disk or analytics. Do not add disk-backed image caches for chat media. Do not include private message content in notification previews, analytics, logs, or crash reports. Keep chat media in memory and follow the existing safety/image pipeline.
4. **Profile stickers are different from chat media.** User profile avatars must be app-owned goofy sticker illustrations, not real user photos. Assign one sticker identifier when the profile is created and keep it stable across sessions/devices. Store only a small asset/sticker key as profile metadata if the current data contract supports it; do not store an uploaded portrait. Do not randomize the sticker on every rebuild or screen visit.
5. **No runtime font downloads.** Bundle licensed font files as app assets. Do not use `google_fonts` runtime fetching.
6. **Retain safety protections.** Keep `ScreenProtector`/FLAG_SECURE, the profanity filter, image guard, explicit 18+ and terms consent (never prechecked), and report/block access. Improve presentation and reachability; never remove protections as a design shortcut. Preserve a debug-only screenshot path using `--dart-define=ALLOW_SCREENSHOTS=true`; default production behavior remains protected.
7. **Honest state.** Never show “request sent”, “reported”, “blocked”, “saved”, “notification delivered”, or “subscription active” unless the relevant operation actually succeeded. Model pending, success, failure, unavailable, and retry states truthfully.
8. **Server owns matching and entitlements.** The client may display available filters, remaining free uses, and subscription state, but it must not be the authority for gender eligibility, free-use limits, country matching, queue priority, or VIP access.
9. **Do not request precise location for matching.** Distance/radius filtering is removed. Country matching must not expose coordinates, street-level location, or distance to another user.

## 1. Visual direction: Milky Sage × Editorial Lounge

Use the supplied screenshots as the visual reference for hierarchy and layout, while retaining the previously approved Milky Sage palette. The target should feel like a calm, slightly literary “stranger lounge”: warm paper, elegant serif headlines, thin rules, quiet navigation, confident whitespace, and small moments of playful sticker art. It should not look like a generic dating-app template or a dashboard full of cards.

### Visual principles

- **Canvas:** warm milk/off-white, close to paper; avoid cold grey and stark pure white as the page background.
- **Surfaces:** soft white/milky panels with fine hairline borders. Prefer open layouts and horizontal separators over wrapping every row in a floating card.
- **Accent:** muted sage for selected states, small highlights, sticker palettes, and quiet illustrations.
- **Actions:** deep forest green for primary actions, with accessible light text. Keep buttons confident and simple; no coral, neon, glossy gradients, or heavy glow.
- **Typography:** editorial high-contrast serif for large page headlines and section titles; Figtree (or similarly legible bundled sans) for body, forms, navigation, and chat. Use italic serif for short secondary notes only. Small uppercase labels may use increased tracking.
- **Layout:** generous whitespace, thin dark/neutral rules, disciplined alignment, asymmetry where it adds character. Do not copy the reference brand name “Kindred”, its exact marketing copy, sample portraits, or sample prices. Keep the product name StrangrChat.
- **Illustration:** replace profile photography with random goofy app-owned sticker art. Do not use emoji as a substitute for designed sticker assets.
- **Motion:** restrained and purposeful. Use subtle fades, small slides, tactile press feedback, and gentle sticker motion. Avoid particle storms, constant pulsing, large parallax, and attention-grabbing animation on every control.

### Colour tokens

Define tokens once (for example in `lib/app/tokens.dart`) and use them through `ColorScheme`/theme extensions. These are starting values; run contrast checks on actual rendered pairings before shipping.

| Token | Light / primary | Dark / supporting | Purpose |
|---|---|---|---|
| `bg` | `#F8F7F2` | `#18221B` | warm milk page canvas |
| `surface` | `#FFFDFC` | `#202C24` | sheets, panels, input backgrounds |
| `surfaceHigh` | `#EEF1EA` | `#2B392F` | received bubbles, selected soft surfaces |
| `outline` | `#DFE0D8` | `#405044` | quiet separators and hairlines |
| `outlineStrong` | `#788579` | `#819485` | visible control borders; verify 3:1 |
| `text` | `#20241F` | `#F1F2EC` | primary text |
| `textMuted` | `#566157` | `#B8C1B7` | secondary text |
| `forest` | `#315B43` | `#A8C4AA` | primary action / selected control |
| `onForest` | `#FFFFFF` | `#172019` | text/icons on primary action; verify contrast |
| `sage` | `#829A80` | `#A0B89E` | selected state, sticker accents, illustration |
| `sageSoft` | `#E1E9DD` | `#34483A` | quiet selected fill |
| `success` | `#28734D` | `#8FC49D` | positive state |
| `danger` | `#B4233A` | `#F08A9B` | report, destructive actions |
| `ink` | `#242521` | `#F1F2EC` | strong rules and editorial emphasis |

Rules: body text must meet WCAG 2.x 4.5:1; large text and meaningful UI boundaries need at least 3:1. A subtle outline is decorative and cannot be the only affordance for a control. Do not rely on colour alone for unread, online, error, or selected states. Dark mode must be contrast-tested independently; the light editorial theme is the primary reference.

### Typography

- Display: **Cormorant Garamond** or another bundled high-contrast editorial serif; use italic for the home hero when it matches the supplied design.
- UI/body: **Figtree**; use a Devanagari fallback such as Noto Sans Devanagari if Hindi support is enabled.
- Bundle fonts locally and include their licence files. Verify exact font assets and family names before adding them to `pubspec.yaml`.
- Suggested scale: display 48–60/0.98–1.05 line-height on wide layouts, 40–48 on compact layouts; page title 32–38; section title 26–32; body 15–17/1.45; labels 11–13 with tracking; chat body 16/1.4.
- Keep the serif expressive and sparse. Do not render every label or button in serif. Test text scaling at 200%; never clip text to preserve a composition.

### Shape, space, and elevation

- Prefer square/low-radius editorial controls for desktop/tablet surfaces; use 12–18 px radii for compact mobile controls and 18–24 px for sheets where appropriate. Do not force pill shapes onto every element.
- Use a consistent 4/8/12/16/24/32/48 spacing scale.
- Use thin separators and very subtle shadows. No stacked shadows or blurred glass everywhere.
- Keep one clear focal point per screen and allow whitespace to do its job.

## 2. Global navigation and notification bell

- The app shell must provide a consistent top-level notification bell with an accessible label, a visible unread indicator/count, and a meaningful tap target.
- On wide layouts, use a restrained top navigation bar: StrangrChat wordmark/descriptor on the left, main destinations, then notification bell and sticker avatar on the right. Avoid copying the “Kindred” name from the reference.
- On Android/mobile, adapt to a compact app bar. Keep the notification bell near the top-right. Put primary destinations in the existing mobile navigation pattern (for example bottom navigation) rather than squeezing desktop links into the header.
- Tapping the bell opens a notifications inbox. On wide layouts it may be a right-side drawer over a dimmed background; on mobile use a modal sheet or full-screen inbox with a clear close/back affordance.
- The inbox should support unread/read visual states, time labels, “Mark all as read”, and opening the relevant destination. Include only notification types backed by real product events: friend request, message request/new chat activity, new match, subscription/trial/payment state, and chat-expiry reminder where implemented.
- Use short, privacy-safe copy. Never display message body text, sensitive profile data, or exact location in the inbox or OS push preview. Distinguish unread state by both a marker and weight, not colour alone.
- Empty, loading, permission-denied, offline, and error states need deliberate UI. Do not fabricate example notifications in production.
- **Backend dependency:** verify the existing event model, inbox storage/read state, delivery channel, and routing payloads before wiring UI. Do not invent socket names or notification APIs. If absent, build the visual shell only and clearly report the missing integration contract.

## 3. Required product behavior and filter rules

### 3.1 Remove distance; add same-country matching

- Remove distance, nearby, radius, kilometre/mile sliders, distance badges, and distance-based copy from every matching screen, filter sheet, saved preference, and empty/waiting suggestion.
- Replace the distance control with a simple **Same country** toggle/filter. When enabled, the match pool must be restricted to the user's country; when disabled, the user may enter the supported global pool.
- Do not request GPS permission or display distance. Prefer a trusted country code already known by the service/account; do not infer a country from a street location or expose a precise location.
- The server must enforce the actual queue constraint. The client only displays and submits the supported preference using an already-defined contract. If the current backend has no country preference or matching enforcement, flag it as a backend dependency rather than implementing a client-only illusion.
- Update all search/wait copy: never suggest “Try Nearby” or “increase radius”. Use choices that exist, such as relaxing Same country or changing the gender/intent filter if allowed.

### 3.2 Gender matching and the Female filter allowance

- The Female gender-match filter has **three free uses**, after which the user must subscribe to continue using that filter. Present the remaining allowance clearly and calmly (for example, “2 free uses left”) without fake urgency.
- On the third-use boundary, show a concise VIP/subscription explanation and a clear way to see plans. Do not imply that the entire app is locked; only the gated filter/match action is gated.
- Do not invent whether the three uses reset daily, monthly, or never; that cadence is not specified. Do not invent whether a use is consumed when the user opens the filter, joins the queue, or receives a match. Confirm the exact consumption event and reset policy against the product/backend contract.
- The server/entitlement layer must be the authority for the remaining count and subscription access. Never rely on a local counter, hidden button, or client-only check to enforce access. If the API does not expose remaining uses / entitlement state, report the missing contract.
- Keep other gender options and the selection state consistent with the actual product/backend rules. Do not assume or create extra gender identities or restrictions not present in the app's model.

### 3.3 Random goofy sticker profile avatars

- New profiles receive a random sticker illustration from a bundled, app-owned sticker pack. No real-person portrait or profile-photo upload is used for profile identity.
- Include a deliberately art-directed pack of varied goofy characters/objects (for example odd little creatures, expressive fruit, tiny monsters, abstract mascots). Stickers should have a coherent outline/texture and varied silhouettes; avoid repetitive coloured circles with generic icons.
- Assign the sticker once at profile creation. Persist a stable `stickerId`/asset key as profile metadata only if the existing profile contract supports it; otherwise document the required profile metadata change for backend review. Keep the assigned sticker consistent in profile, app bar, friends list, chat header, friend-request rows, and notification items.
- Never pick a new sticker on every widget rebuild. Use a stable assignment seeded/generated once per profile, not a random call inside `build()`.
- Replace profile “Change photo”/photo upload UI with a “Your sticker” preview. Do not remove `image_picker` from the project if it is used for ephemeral chat image sharing; only remove profile-photo affordances.
- Keep sticker assets local and licensed. Do not fetch avatars from remote image services, use user-generated portraits, or use emoji as a visual substitute.

## 4. Screen blueprints

Adapt to Android first and responsive widths. The screenshot references are web-sized; preserve their visual logic, not their desktop pixel dimensions.

### 4.1 Home / matching

- Header: StrangrChat wordmark; primary destinations on wide layouts; notification bell with unread state; current user's assigned sticker avatar.
- Hero: a small tracked uppercase eyebrow, a large editorial serif headline (can be italic), a short human explanation of ephemeral matching, and two actions: a strong **Start a random chat** primary CTA and a quiet **See plans** link/button.
- Keep the primary action visible without scrolling through a long filter form. Do not make a large Orb the main home CTA; the Orb may remain a supporting search/match motif.
- Below the hero, use a restrained visual/sticker composition or paper-like texture. Avoid generic stock photos and overdecorated gradient blobs.
- Put matching preferences in a compact “Match preferences” section or sheet. Include gender selection, Same country, intent/interests, and only options actually supported. Do not include distance/radius/city proximity.
- The gender option should show the remaining free Female-filter uses when the server exposes it. When exhausted, show the subscription gate with clear plan details.

### 4.2 Searching and match found

- Searching should feel calm and alive: small sage Orb/rings or sticker constellation, short rotating copy, and a visible Cancel action. One loop per screen maximum; respect reduced motion.
- Never show fake user counts or claim a match is imminent. No “Nearby” or distance suggestions.
- Match-found moment: two assigned sticker avatars meet briefly, a subtle sage highlight, and a clear “Connected” state before entering chat. Do not show real profile photos.
- Match state and all queue outcomes must reflect backend events. Handle timeout, cancellation, queue error, partner-left, and retry explicitly.

### 4.3 Chat

- Header: assigned sticker avatar, neutral partner label/alias, online/connection state only when real, Add friend with real pending/accepted/error states, and a visible Safety entry for report/block.
- Keep safety reachable in one tap. Report/block actions must not claim success until confirmed by backend.
- Message bubbles are quiet and readable: incoming bubble on a soft surface, outgoing bubble in forest green with accessible text. Group consecutive messages, use timestamps sparingly, and animate only newly received messages.
- Composer is simple and thumb-friendly. Send state is clear; profanity warnings are inline and accessible. Keep chat images in memory only and retain the existing safety validation flow.
- Skip/Next belongs near the composer and should require deliberate confirmation if leaving destroys an ephemeral conversation.
- Partner-left/chat-ended must become an explicit state, not an empty composer under a “Searching” title. End copy can say “Chat ended. Nothing was saved.” only if that statement matches actual storage behavior.

### 4.4 Kept strangers / Friends

- Use an editorial page title such as “Kept strangers” and a small saved count. Use thin horizontal separators, not a grid of heavy cards.
- Each row: stable sticker avatar, display name/alias, optional short bio or last-chat note, online/last-seen indicator, a clear chat action, and a separate remove action.
- Presence labels must reflect real timestamps/status, never hardcoded “now”. Do not reveal precise location or distance in friend summaries.
- Chat action must actually open/resume a conversation with that friend; if the current product cannot do this, don't label a route-only navigation “Chat now”.
- Removing a friend uses a confirmation sheet or undo affordance. The result message must reflect real completion.
- Empty/loading/error states follow the same paper/editorial system.

### 4.5 Subscription / VIP

- Page title uses an editorial headline (for example, “Choose your place in the lounge”) with one concise explanation.
- Compare Free, Plus, and Pro only if those exact tiers and benefits exist in the current product/store configuration. Use clear columns at wide widths; stack them on narrow Android screens without horizontal clipping.
- One featured tier may use a deep forest fill with contrasting text, but do not overuse dark panels. Keep the other tiers milky with fine borders.
- Preserve real localized store prices, purchase flow, restore purchases, renewal disclosures, and semantics. Never copy dollar values from reference screenshots or invent prices/perks.
- The gender-filter three-use gate should link to this page and state exactly what subscription unlocks. No false countdowns, fake scarcity, or preselected expensive plan.

### 4.6 Profile / “Your corner”

- Use a clear page title and thin divider. At wide widths, sticker preview can sit in a narrow left column with profile fields/settings on the right; stack vertically on mobile.
- Show the assigned goofy sticker as the profile identity. No “Change photo”, camera button, gallery picker, or real-person portrait upload for profile avatar.
- Display name and bio fields should be simple, with labels above controls and sensible character limits based on actual model constraints.
- Settings such as online status, read receipts, and match notifications should reflect real preferences and backend capability. Use accessible switches and clear saved/unsaved/error feedback.
- Save should be disabled while unchanged and have loading/success/failure states. Never show “Saved” before persistence confirms.

### 4.7 Notifications inbox

- Match the supplied reference: a right-side notice panel over a dimmed home screen on wide layouts; full-screen or modal sheet on Android.
- Header: “Notices”/“Notifications”, Mark all as read, close/back. Rows use a small unread square/dot, concise title, muted secondary sentence, and compact uppercase relative timestamp.
- Prioritise friend requests and message requests, then match events and relevant subscription/expiry notices. Add actions such as Accept/Decline or Open only if the existing service supports them.
- Tapping a notice opens the correct destination and marks it read only when the backend contract specifies that behavior. Bulk mark-read must handle loading/failure.
- Never include private chat message text in notification body or push preview. Use neutral copy such as “You have a new message request.”

### 4.8 Onboarding

- Lead with the editorial brand and one human promise, not jargon. Keep onboarding short.
- 18+ confirmation and terms/zero-tolerance consent remain explicit and unchecked by default. Preserve anonymous session bootstrap behavior.
- Explain that profile identity uses a random sticker, not a real photo, if profile setup is introduced.

### 4.9 Safety / report and block

- Use a calm bottom sheet with clear Report, Block, and Just skip actions and report-reason choices.
- Do not tell the user a report was filed or a block persisted unless the backend confirms it. If the endpoint/event is missing, label the current action honestly and raise the backend dependency.
- Danger uses its own accessible semantic colour and icon; never use forest/sage as the danger signal.

## 5. Shared components and interaction language

Build and reuse shared tokens/components before polishing every screen independently:

- `EditorialScaffold` / page header and divider pattern
- `EditorialButton` (forest primary, quiet secondary/link variant)
- `AppTextField`, `AppToggleRow`, `AppChip`, `AppSheet`
- `NotificationBell` and `NotificationInbox`
- `StickerAvatar` (stable sticker key, no photo fallback)
- `PresenceIndicator` with text semantics
- `Toast` overlay for transient confirmation/error
- `SkeletonRow` / `SkeletonBox`
- `Orb` only for search/match supporting motion

Use `AppTheme.light` and `AppTheme.dark` with explicit `ColorScheme` values; `themeMode: ThemeMode.system` is acceptable if both themes are complete. Define typography, colour, spacing, border, and motion tokens once. Do not hardcode style values across features.

## 6. Motion and accessibility

- Motion tokens starting point: fast 120 ms, base 220 ms, slow 380 ms, hero 700–900 ms.
- Entrances use ease-out; exits ease-in; shared movement uses a restrained emphasized curve. Use springs sparingly for press feedback and sticker/avatar interactions.
- Reduced motion (`MediaQuery.disableAnimationsOf(context)`) means no looping animations, parallax, or particle effects; use short fades or static states. Respect the system and any in-app preference.
- Haptics are optional feedback, never the only signal. Provide a settings toggle and respect disabled state.
- Every icon-only control has a semantic label and tooltip. Notification badge/unread state must be announced. Animated match/status transitions should have concise semantic announcements.
- Test TalkBack, keyboard navigation where relevant, contrast in both themes, and 200% text scaling.

## 7. Build order for a broad redesign

1. Re-read current code and backend contracts; make a list of verified screens, routes, state models, assets, and missing product dependencies.
2. Add colour/type/spacing/motion tokens and theme support.
3. Create editorial primitives and `StickerAvatar` with stable IDs/assets.
4. Build app shell navigation and notification bell/inbox states.
5. Redesign Home and matching preferences (remove distance; add Same country; implement visible gender allowance state only from server data).
6. Polish search/match/chat/end states and safety.
7. Redesign Friends, Subscription, and Profile.
8. Run accessibility, responsive layout, privacy, and performance checks.

For each screen deliver: widget changes, all loading/empty/error/success states, responsive behavior, motion spec, semantics, tests, and a list of backend decisions or missing contracts.

## 8. Quality checklist for every PR

- [ ] Current branch inspected; audit findings reverified before relying on them.
- [ ] Uses shared tokens/components; no one-off hardcoded style values.
- [ ] Milky Sage editorial look: warm milk background, serif display, Figtree UI, thin rules, whitespace, restrained forest/sage accents.
- [ ] No copied “Kindred” branding, screenshot prices, sample names, or sample notification data.
- [ ] No profile photos: profiles use stable bundled sticker IDs; no profile photo-picker/upload flow.
- [ ] Distance/radius/nearby UI removed everywhere; Same country replaces it without GPS permission.
- [ ] Female filter has the specified three free uses; source of remaining count and reset/consumption policy verified server-side; no invented reset.
- [ ] Notification bell is visible and accessible; inbox states and event types map to real backend events; no private message previews.
- [ ] No false friend/report/block/save/purchase/notification success copy.
- [ ] All states designed: idle, searching, matched, partnerLeft, error, offline, empty, loading.
- [ ] Text contrast at least 4.5:1; meaningful UI controls at least 3:1; dark theme separately verified.
- [ ] Reduced-motion path and haptics preference work.
- [ ] No chat text/image disk writes, remote fonts, private analytics, or notification content leakage.
- [ ] Safety is reachable in one tap from chat.
- [ ] 200% text scale and low-end Android performance checked.

## 9. Anti-slop rules

- One strong idea per screen. Do not fill empty space with decorative cards or random gradients.
- Avoid generic icon-in-circle hero patterns, repeated identical cards, heavy shadows, and default Material demo styling.
- Use expressive serif headlines sparingly; keep controls and body copy straightforward.
- Use sticker illustrations as a coherent designed system, not emoji or profile photos.
- Copy should be short, human, specific, and honest. Do not promise safety or privacy capabilities the code does not provide.
- Prefer a few well-crafted components and local assets over unnecessary packages.
