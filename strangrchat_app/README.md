# StrangrChat Flutter app

The app uses Flutter, Riverpod, `go_router`, and the existing Node.js/Socket.IO
service. Its Peach Pop styling uses bundled vector sticker illustrations and
local system fonts; it does not download fonts at runtime.

## Current backend limits

- First-run onboarding sends the required name, age, and country plus optional
  city to `/auth/anonymous`, which updates the anonymous user for the existing
  device ID. The server requires a successful hCaptcha verification and rejects
  users under 18. Location fields remain profile data; they are not copied into
  matching preferences. Redis also limits sign-up attempts to 10 per device and
  60 per IP per 10-minute window.
- The queue currently applies conversation intent only. Gender eligibility,
  the Female-filter free-use allowance, and Same country matching are not
  authoritatively implemented; the app does not expose them as working filters.
- Friend requests, accepted-friend listing, reporting, and blocking are backed
  by authenticated API routes. Accepted-friend chat uses authorized Socket.IO
  rooms and relays message bodies in memory only; the conversation is not
  persisted. The notification inbox is still unavailable and the home bell
  does not show a fabricated unread indicator.
- The VIP purchase client calls `/vip/validate-purchase`, but this repository's
  server does not currently implement that route. VIP stays unavailable unless
  the deployed server validates the purchase.
- Random and friend chat messages are relayed without server persistence and
  held in memory only while the conversation is open. Image sharing is disabled
  until server-side image moderation is available; the existing image safety
  classifier is only a placeholder.

Screenshot protection remains enabled unless a debug build is launched with
`--dart-define=ALLOW_SCREENSHOTS=true`; release builds always keep protection.

## hCaptcha setup

1. Create a free site in the [hCaptcha dashboard](https://dashboard.hcaptcha.com/)
   and copy its public site key. Add the hostname used by your app to that site's
   allowed hostnames. The WebView challenge uses the HTTPS origin configured
   below; use a hostname you control in production.
2. Set the private secret key only in the backend environment. In
   `strangrchat_server/.env`, configure (start from
   `strangrchat_server/.env.example` and replace every placeholder):

   ```dotenv
   HCAPTCHA_SECRET=your-private-secret-key
   HCAPTCHA_SITE_KEY=your-public-site-key
   HCAPTCHA_ALLOWED_HOSTNAMES=captcha.example.com
   ```

   Never put the secret in Flutter, commit it, or send it to the app.
   Configure a strong `JWT_SECRET` of at least 32 characters as well. Apply
   pending database migrations from the server directory with
   `npx prisma migrate deploy`, then run `npm run build` before starting the
   production API.
3. Build/run Flutter with the public key and the same challenge hostname:

   ```sh
   flutter run \
     --dart-define=HCAPTCHA_SITE_KEY=your-public-site-key \
     --dart-define=HCAPTCHA_HOSTNAME=captcha.example.com
   ```

   On mobile, `HCAPTCHA_HOSTNAME` defaults to `captcha.strangrchat.app` and
   should be set to the HTTPS challenge hostname used by your native WebView.
   Chrome runs the hCaptcha widget from the browser's actual origin, such as
   `localhost` or your machine's LAN IP; add that hostname to the hCaptcha
   site's allowed hostnames and to the backend's comma-separated
   `HCAPTCHA_ALLOWED_HOSTNAMES` list. For example, local testing can use
   `HCAPTCHA_ALLOWED_HOSTNAMES=localhost,192.168.31.141`. The server still
   verifies every token with hCaptcha and rejects any hostname not on this
   explicit allowlist. Without keys, onboarding stays disabled rather than
   bypassing verification.

## Validation

From this directory, run `flutter analyze` and `flutter test`.
