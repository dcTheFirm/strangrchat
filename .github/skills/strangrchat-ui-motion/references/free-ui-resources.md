# Free/open-source UI resources evaluated for StrangrChat

Checked on 5 Nov 2026. Always re-check current release, licence text, and dependencies before adding a package to the app. These are optional accelerators, not a reason to replace StrangrChat's architecture.

## 1. Flyer Chat — recommended candidate for chat UI only

- Package: [`flutter_chat_ui`](https://pub.dev/packages/flutter_chat_ui)
- Documentation: <https://flyer.chat/docs/flutter/introduction/>
- Repository: <https://github.com/flyerhq/flutter_chat_ui>
- Current package page checked: `2.12.0` on 5 Nov 2026.
- License: Apache-2.0.
- Why it fits: backend-agnostic, customizable Flutter chat UI with builder/theme options; can be considered for message rendering and composer presentation while retaining the existing backend.
- Constraints: inspect its current `flutter_chat_core` API, dependencies (including any cross-cache behavior), and message model mapping first. Do not enable persistent disk caching for ephemeral chat images or text. Do not use any hosted backend integration. Keep the current Node.js/Socket.IO contract and in-memory message lifecycle.
- Recommendation: optional. If its caching model or package integration conflicts with the no-persistence requirement, build custom chat bubbles/composer using Flutter widgets instead.

## 2. Weekend — full Flutter dating/social app reference

- Repository: <https://github.com/zypherlabs-bit/Weekend>
- License: MIT (as stated by the repository on the check date).
- Why it may help: complete Flutter social discovery/dating app reference with discovery, matching, and chat concepts.
- Constraints: its architecture uses Supabase and location-based discovery. StrangrChat must not migrate to Supabase or restore distance/GPS matching as part of a UI refresh. Treat it as a code/design study only; do not transplant backend, schema, auth, or location logic.

## 3. Love Luster UI Pack — optional visual asset inspiration

- Page: <https://cjlaserna.itch.io/love-luster-ui-pack>
- The pack describes a free/name-your-price dating-sim/visual-novel UI asset collection with PNG exports and Figma files.
- Stated licence: CC BY 4.0, including commercial and non-commercial use with attribution.
- Fit: not a complete social/dating mobile app kit. Consider only small decorative elements if they visually fit. Preserve attribution and keep a record of the original licence page in the project's asset notices.

## Integration rule

Before installing anything, check whether the existing app already has an equivalent widget or dependency. Review pubspec constraints, license, transitive packages, media caching, accessibility, and privacy. Prefer borrowing isolated UI ideas over replacing current screens wholesale. A UI kit must not add a second source of truth, authentication provider, database, subscription manager, or notification service.
