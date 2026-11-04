# StrangrChat visual references and product requirements

These notes are derived from the five screenshots supplied on 4 Nov 2026. They describe the intended visual direction and new product requirements; they are not proof that the current app or backend already implements them.

## 1. Reference screens studied

1. **Home:** thin top navigation, wordmark and small tracked descriptor, notification bell and avatar; small uppercase eyebrow; large expressive italic serif headline; short sans-serif explanation; dark/strong primary CTA and quiet secondary plans link; broad calm visual area below.
2. **Kept strangers / Friends:** editorial page title and saved count; horizontal divider; simple full-width rows; circular portrait in reference, display name and italic micro-bio; online/last-active marker; separate chat and remove actions; fine separators rather than card grid.
3. **Subscription:** large serif heading and short description; three side-by-side tier columns on wide layouts; Free, Plus, Pro hierarchy; one featured dark middle tier; benefit checklists; simple bottom-aligned choice buttons.
4. **Profile / Your corner:** strong serif title and divider; profile visual on left with editable details and preference switches on right; labels above fields; simple save action.
5. **Notifications / Notices:** a right-side inbox panel over a dimmed page; heading, Mark all as read and close; chronological notification rows; unread markers; concise title, secondary text and compact timestamp.

The screenshot brand name “Kindred”, its wording, human portraits, sample user names, sample messages, prices, and trial details are reference-only. Do not copy them. Use StrangrChat's own brand, real product copy, actual user data, and configured store prices.

## 2. Reconcile with the approved Milky Sage theme

The screenshots provide the editorial structure; Milky Sage remains the approved colour direction. Use warm off-white/paper as the canvas, milky surfaces, charcoal/ink typography and hairlines, sage as a quiet accent, and deep forest green as the primary action. One subscription tier may use a deep forest panel as the featured comparison column. Keep gradients and shadows minimal.

The screenshots use high-contrast serif display lettering and sans-serif utility text. Use a locally bundled editorial serif (for example Cormorant Garamond) for display/page headings and Figtree for navigation, body, forms, and chat. Use restrained italic serif or italic microcopy selectively. Never download fonts at runtime.

## 3. Responsive interpretation

The screenshots are desktop/tablet browser compositions, while StrangrChat is a Flutter Android app. Preserve their hierarchy, not their exact pixel layout.

- **Wide layouts:** top horizontal nav; notification inbox can slide from the right; subscription tiers in columns; profile in two columns; friends list as full-width horizontal rows.
- **Phone layouts:** compact app bar with notification bell at the top-right; use the app's bottom navigation or another existing mobile destination pattern; notifications become a modal sheet/full-screen inbox; subscription tiers stack vertically; profile sections stack; friend rows retain readable action targets without horizontal overflow.
- Avoid fixed heights that clip content. Handle keyboard, safe areas, 200% text scale, and narrow devices.

## 4. Product requirements supplied by the user

### Notifications

- Show a notification bell in the top bar.
- The notification experience covers real product notifications, especially new friend requests and new message requests.
- The screenshot also inspires a chronological notice inbox with unread indicators, mark-all-read, timestamps, and a close/back action.
- Other categories (for example new match, subscription/trial status, or chat-expiry reminder) should appear only if those events exist in the product.
- Keep notification copy privacy-safe: never expose private chat text in an inbox or OS preview.
- Backend event delivery, inbox persistence, read state, push configuration, and destination routing must be checked before implementing interactions. These screenshots do not provide an API/socket contract.

### Same-country preference instead of distance

- Remove distance/radius/nearby matching controls and copy.
- Add a Same country preference.
- Do not request GPS or expose precise location. Country source and enforcement need to be trusted and server-authoritative.
- If current APIs/models do not support it, call out the backend dependency; do not fake the behavior in Flutter.

### Female gender-filter allowance

- The Female gender-match filter is available for three free uses; further uses require a subscription.
- The screenshots do not specify reset cadence or exactly when a use is consumed. Do not invent daily/monthly/lifetime resets or count-consumption semantics.
- The remaining count and subscription entitlement need to come from the server/store authority. Do not secure the gate with client-only logic.

### Random sticker identity

- Every new profile gets one random goofy sticker illustration as its identity.
- Do not use the user's real photo as their profile picture; remove profile-photo upload/change affordances.
- Use an app-owned, locally bundled sticker pack. Assign once at profile creation and keep the sticker stable across screens and sessions.
- Persist only the sticker asset key/ID as profile metadata if supported by the existing backend contract. This does not change the rule that ephemeral chat content must not be persisted.
- The sticker avatar should appear consistently in the app bar, profile, friends, chat header, friend-request rows, and notices.

## 5. Visual acceptance criteria

- Home communicates the product immediately with one editorial headline, a short supporting sentence, a strong start-chat action, and a secondary plans action.
- No long filter form pushes the primary action below the fold.
- Friends are easy to scan, with thin separators and sticker avatars.
- Subscription benefits and price are easy to compare; mobile plans do not require sideways scrolling.
- Profile settings are plain and easy to edit; avatar is a sticker, not a photo.
- The notification bell and inbox states are obvious and accessible.
- No distance/radius/nearby option remains.
- The Female filter allowance is visible and honest; the app does not invent a reset policy.
- The design feels like a coherent editorial lounge in Milky Sage, not a direct clone of the supplied reference brand.
