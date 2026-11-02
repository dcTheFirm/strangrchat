# strangrchat — MASTER IMPLEMENTATION PROMPT

Act as a senior DevOps, Backend, and Flutter Mobile Engineer. We are building **strangrchat**, a high-speed, privacy-first anonymous social discovery and chat application designed for Android and iOS (targeting India).

## 1. Core Non-Negotiable Architecture Rules
*   **Zero Chat & Image Persistence:** Text messages and shared images must **NEVER** be stored in PostgreSQL or on disk. They must be relayed in real-time via **Socket.IO (RAM only)** and cleared immediately after delivery. The **only** exception is when a user clicks **"Report User"**, which submits a snapshot of the offending message/metadata to the `moderation_reports` table for legal compliance.
*   **Minimal Database Footprint:** Use **PostgreSQL 16** (via Prisma ORM) strictly for essential records: users, preferences, friend connections, subscriptions, and moderation reports.
*   **In-Memory Smart Matchmaking:** Use **Redis 7** for all live matchmaking queues, online presence, rate limiting, and instant filter matching (Nearby GPS radius, Intent, City, Country, Hobbies, Gender).
*   **Anti-Mod APK & Server Authority:** The Flutter client has zero authority. Every swipe, gender filter request, and image upload limit must be validated by the Node.js server against the user's active PostgreSQL subscription status. 
*   **Single-VM Docker Compose Deployment:** Package the entire backend stack (`caddy`, `backend`, `postgres:16-alpine`, `redis:7-alpine`) in a clean `docker-compose.yml` designed for an Oracle Cloud Free VM.

## 2. Security & Privacy Guards
*   **Block Screenshots & Screen Recording:** Enforce Android `FLAG_SECURE` across all chat and profile screens.
*   **Profanity & Threat Filter:** Block Hinglish/English abusive words, threats, and CSAM keywords on both the client and server. Auto-increment strikes (3 strikes = device/account ban).
*   **On-Device NSFW Image Blocker:** Compress images (`~80 KB` limit) and run an on-device TFLite NSFW classifier *before* transmission. Block explicit images locally.
*   **Google Play Integrity API:** Verify the app binary to block modified/cracked APKs from connecting to the backend.

## 3. VIP Subscriptions (Google Play Billing)
*   **Free Tier:** Random gender match, limited daily image shares (e.g., 3/day), limited daily friend requests.
*   **VIP Tier (e.g., ₹49/48-hr or ₹199/month):** Unlocks Gender Filter (Male/Female), exact City/Radius selection, unlimited image shares, unlimited friend requests, and removes ads.
*   **Verification:** Use Google Play Developer API on the Node.js backend to verify the encrypted `purchaseToken` before granting the entitlement in the database. Support "Restore Purchases".

## 4. Friend System ("Talk Later")
*   Users can send a "Friend Request" during an active chat. 
*   If accepted, the connection is saved in PostgreSQL, and Redis tracks their live online status. 
*   Friends can start a new live chat later, but previous messages and images remain entirely ephemeral and are never restored.

## 5. PostgreSQL Prisma Schema (The Only 5 Tables Allowed)
1.  `User`: `id` (UUID), `deviceId`, `isAdultVerified` (Boolean), `strikeCount` (Int), `isBanned` (Boolean), `createdAt`.
2.  `UserPreference`: `userId` (UUID), `gender`, `intent` (`FRIENDS`, `RELATIONSHIP`, `MARRIED`, `TIPS`), `countryCode`, `city`, `hobbies` (String[]).
3.  `Friendship`: `id`, `user1Id`, `user2Id`, `status` (`PENDING`, `ACCEPTED`), `createdAt`.
4.  `Entitlement`: `id`, `userId`, `playPurchaseToken`, `planType`, `expiresAt`, `isActive`.
5.  `ModerationReport`: `id`, `reporterId`, `reportedUserId`, `reason`, `messageSnapshot` (Optional String), `createdAt`.

## 6. Implementation Phases (Step-by-Step)
*   **Phase 1 — Infrastructure & Database:** Create `docker-compose.yml`, `.env.example`, and the Node.js `strangrchat_server` with the Prisma PostgreSQL schema.
*   **Phase 2 — Matchmaking & Ephemeral Chat:** Implement the Redis 7 matchmaking engine, anonymous session auth, and Socket.IO real-time text/image relay (with RAM-only constraints).
*   **Phase 3 — Flutter App Foundation:** Initialize the `strangrchat_app` with `go_router`, Riverpod, `FLAG_SECURE`, and the 18+ consent flow.
*   **Phase 4 — Core UI & Safety:** Build the Smart Filter Home screen, live chat UI, on-device NSFW filter, and Hinglish profanity block.
*   **Phase 5 — Friend System & Subscriptions:** Implement the Friends tab, Google Play Billing checkout, Server-side receipt verification, and Mod-APK server locks.
