# StrangrChat UI reference specification — Peach Pop

This document translates the user's latest supplied mobile dating/matching/chat screenshots into a Flutter design specification. Screenshots are bundled in `visuals/`:

- `01-onboarding-discovery-match.png` — onboarding orbit, discovery/matches, match celebration.
- `02-chat-list-conversation.png` — chat list and one-to-one conversation.
- `03-full-flow-overview.png` — multi-screen overview showing onboarding, discovery cards, match, conversation, and list.

The images are a style and composition reference, not product truth. They show human portraits and message excerpts; StrangrChat's requirements override those elements: use app-owned goofy sticker avatars instead of user photos, and never persist chat messages or display saved message snippets from ended ephemeral chats.

## 1. What the references look like

### A. Onboarding and discovery

- Warm gradient presentation background blending peach, pink, and lilac.
- Tall, rounded phone screens with warm cream/white interior surfaces.
- Onboarding hero built from small circular avatars arranged around a central illustration, dotted orbit paths, small heart/speech decorations, and generous negative space.
- Bold, centred headline with one line visually emphasized in coral; short supporting line; one prominent rounded coral-to-orange CTA; small page indicators.
- Discovery screen uses a compact top bar, horizontal “New Matches” avatar strip, a prominent profile/discovery card, and dark capsule bottom navigation with a coral active icon.
- Match celebration uses a short headline, two large overlapping profile visuals, a divider/short explanatory copy, and a strong “Say Hello” CTA with a low-emphasis Later option.

### B. Chat list and conversation

- Rounded search control near the top of the list.
- Lightweight conversation rows with circular avatar, display name, one safe status/preview line, time aligned to the trailing edge.
- Some rows visually rise above the list using a white floating surface and soft shadow, creating a little depth without enclosing every row in a heavy card.
- Conversation uses a compact header with back, circular avatar, alias, online label only when real, and overflow action.
- Message bubbles are rounded and soft; incoming and outgoing bubbles have distinct warm neutral treatments. Timestamps are small and muted. Composer is pinned to the bottom with an emoji/attachment affordance and a round send button.
- Bottom navigation is a dark rounded capsule; selected tab is coral/orange and icons are simple.

### C. Full flow overview

- The product is visually coherent across onboarding, discovery, match, profile/discovery detail, conversations, and chat list.
- Rounded card surfaces, warm gradients, circular portraits, dark bottom navigation, and bright coral CTA treatments repeat consistently.
- The overall feeling is playful, friendly, bright, and social rather than formal/editorial.

## 2. StrangrChat adaptation: do not copy incompatible elements

| Reference element | StrangrChat implementation |
|---|---|
| Real-person profile photos | Replace with app-owned goofy sticker illustrations, assigned once and stable |
| “Near You” and distance labels | Replace with truthful discovery/country labels; no km, radius, GPS, or nearby copy |
| Persistent message snippets in chat list | Do not show persisted message text; use safe request/connection status metadata |
| Generic dating-app conversation history | Active chat only; clear messages when ephemeral session ends |
| Reference brand/name | Keep StrangrChat branding |
| Reference CTA and sample names | Use product copy and actual user data |
| Sample pricing, perks, age and online claims | Use configured store/backend data only |

## 3. Design tokens and art direction

Use `SKILL.md` for canonical Peach Pop values. Visual shorthand:

- Screen base: warm cream (`#FFF8F4`) and white (`#FFFEFC`).
- Hero/marketing backdrop: peach → pink → lavender, used selectively.
- Primary accent: coral with tangerine secondary; use dark ink text on bright gradients or a deeper coral for white text after contrast verification.
- Text: deep warm charcoal, with muted warm grey for metadata.
- Surfaces: large rounded cards, soft warm borders, limited diffuse shadow.
- Bottom navigation: dark charcoal capsule with coral selected state.
- Illustration: goofy sticker avatars with expressive faces, props, and varied silhouettes; no photoreal profile art.
- Type: bold modern sans (Bricolage Grotesque or Manrope) plus Figtree for UI/body; bundle fonts locally.

Do not carry forward the previous Milky Sage palette as the primary system. The current user reference supersedes it.

## 4. Screen-by-screen acceptance criteria

### Onboarding

- A visually strong orbit of sticker characters around a small focal illustration.
- Large short headline, clear supporting copy, one primary start/find action.
- Warm gradient hero used as a backdrop, not a page-long gradient wash that reduces legibility.
- 18+ and terms/zero-tolerance controls remain explicit, visible, and unchecked initially.

### Home / discover

- Top actions remain compact; notification bell is visible and tappable.
- A horizontal new-match/sticker strip is shown only when data exists.
- Main discovery card has sticker art, display alias, real approved metadata, and accessible pass/like controls if swipe mode exists.
- “Find someone”/random-chat action remains available and clearly primary.
- No distance, radius, nearby, or GPS permissions. Same country is the geographic matching control.
- Female filter shows authoritative three-free-use state and a real subscription gate after allowance is exhausted.

### Match found

- Two stable sticker avatars meet/overlap with a small heart accent.
- Headline reads as a match/connection only when server state confirms it.
- “Say hello” starts/opens the actual chat. Later dismisses only the celebration, not a server record unless one exists.

### Chat list and requests

- Rounded search, simple rows, sticker avatars, short aliases, time/status metadata.
- Do not show private message body previews. Safe copy may indicate a pending request or new activity without revealing content.
- Separate friend requests/message requests only when supported by actual events and API state.
- Online dots and timestamps must be real, not fixture data.

### Conversation

- Compact header, clear message grouping, two-tone warm bubble system, and bottom-anchored composer.
- New incoming bubble animates once. Existing messages do not animate on every rebuild.
- Chat is memory-only; session end clears bubbles. No local cache, notification previews, or recovery of previous content.
- Safety and leave/skip are available and understandable.

### Navigation

- A dark capsule bottom bar can present the app's current core destinations. Do not add a tab whose route/feature does not exist.
- Selected state uses coral accent and more than colour alone (icon fill/label/shape).
- Use safe area and enough bottom padding for Android gesture navigation and keyboard.

## 5. Responsive and accessibility rules

The supplied references are phone mockups. Implement for real Flutter viewport sizes, not screenshot pixel dimensions.

- Small Android phones: vertical scroll where necessary; no clipped labels, horizontally overflowing plans, or inaccessible tiny icons.
- Large phones/tablets: use wider cards and restrained two-column layouts only where they preserve the mobile character.
- Respect status/navigation bars and keyboard insets.
- Buttons and icon actions should have sufficiently large hit targets and semantic labels.
- Minimum 4.5:1 body-text contrast and 3:1 meaningful UI control contrast; check every coral gradient combination.
- Support text scaling to 200% and system reduced motion.

## 6. What the screenshots do not specify

The screenshots do not define API routes, Socket.IO event names, matching ranking, friend/message request persistence, notification push delivery, subscription product IDs, country source, Female filter reset cadence, or how a swipe is persisted. These must be read from the current code/backend or agreed with the backend owner. Never invent them while recreating the visuals.
