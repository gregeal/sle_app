# P4 Web security checklist

Reviewed: 2026-07-13. Scope: the single-owner Flutter Web session and its AI
Broker. This is an OWASP ASVS Level 1-style implementation checklist, not a
formal certification or penetration test.

## Access and sessions

- [x] Every AI route requires an allowlisted authenticated session.
- [x] Session identifiers are random, stored only as SHA-256 hashes server-side,
  and delivered in `HttpOnly`, `SameSite=Strict`, `Secure` production cookies.
- [x] Authenticated/session-mutating POST routes require a per-session CSRF
  token; unauthenticated passkey-login routes use one-time challenges, while
  OAuth uses state, PKCE, and a separate short-lived `SameSite=Lax` cookie.
- [x] Google identity tokens are signature-, issuer-, audience-, expiry-, email-
  and verification-checked. Passkey challenges are one-time and expire.
- [x] Production refuses to start with an empty email allowlist. Development
  login is hard-disabled in production.
- [x] Production requires a stable random `IDENTIFIER_SECRET`, an OpenAI key on
  the official host, and Google OAuth to bootstrap a fresh database that has no
  passkeys yet.

## Secrets, AI abuse, and privacy

- [x] The provider key exists only in the broker environment/secret store and
  is never returned to Flutter, JavaScript, logs, cookies, or SQLite.
- [x] Text requests use a normalized schema and server-selected model allowlist;
  the browser cannot submit arbitrary provider payloads or endpoints.
- [x] Realtime returns only OpenAI's short-lived client credential; the standard
  key never enters the WebRTC client. The app limits interviews to 20 minutes.
- [x] Per-user burst throttling and atomic daily/monthly budget reservations run
  before the upstream call. Realtime uses a configurable conservative fixed
  reservation because media flows directly between browser and OpenAI. This is
  a quota gate, not direct-stream usage measurement or a guaranteed actual-cost
  cap; an OpenAI project limit/alert is still required.
- [x] The broker derives an opaque per-user HMAC identifier for Flutter database
  isolation and OpenAI safety metadata; it does not expose or send raw email as
  that identifier.
- [x] Audit rows contain identity, route, outcome, status, and timestamp only.
  Prompts, compositions, transcripts, upstream tokens, and secrets are absent.

## Browser and transport

- [x] TLS is required in production; HSTS (two years, subdomains, preload), CSP,
  COOP/COEP, CORP, `nosniff`, frame denial, Referrer-Policy, Permissions-Policy,
  and no-store API caching are added by middleware and asserted in tests.
- [x] CSP permits only same-origin scripts/assets and the OpenAI Realtime SDP
  endpoint. `style-src 'unsafe-inline'` and `wasm-unsafe-eval` are the narrowly
  documented Flutter runtime exceptions; no third-party script is loaded.
- [x] The production build uses `--no-web-resources-cdn`; Noto Sans and
  Flutter's required fallback fonts are vendored with their licenses and a
  custom bootstrap keeps every runtime font/CanvasKit request same-origin.
- [x] Drift runs in browser-local WASM storage with COOP/COEP enabling OPFS;
  each opaque user ID selects a separate database namespace.
- [x] A custom versioned service worker caches only the application shell and
  bundled learning content. `/api/*` and `/auth/*` are never intercepted or
  cached. Offline entry requires an unexpired seven-day opaque profile hint,
  which contains neither email nor session credential.
- [x] The legacy unpartitioned web database is not silently assigned to a new
  user. Existing users are warned that it is not automatically migrated and
  must not clear browser storage if they need that data preserved.

## Verification evidence

- [x] Broker tests cover unauthenticated access, CSRF, allowlisting, model
  restrictions, rate and budget limits, cookie flags, request-size limits,
  Realtime minting, pseudonymous identifiers, readiness failure, retry/release
  behavior, bounded limiter state, and security headers.
- [x] Flutter tests cover the broker gateway and ensure no API key appears in
  client payloads, along with key/destination isolation, web-profile isolation,
  output validation, data, learning, and Realtime lifecycle behavior.
- [x] CI is configured to run broker lint/tests, Flutter analyze/tests, a
  finalized/validated production PWA, a signed Android release build using a
  disposable CI key, and a deployable-container
  readiness/static smoke check. The latest CI run, not a frozen count here, is
  the authoritative pass/fail record.
- [ ] In a clean Chrome profile, complete one authenticated online load, reload
  under an offline network condition, confirm seeded practice still opens, and
  confirm an API request is never satisfied from Cache Storage.
- [ ] After the first real deployment, enter the final URL in Mozilla
  Observatory and archive the report. External scanning cannot be completed
  before a domain and production service exist.
- [ ] Register the production Google OAuth callback and verify a real passkey,
  microphone permission, Realtime interview, and five-dimension report in a
  clean Chrome profile.
