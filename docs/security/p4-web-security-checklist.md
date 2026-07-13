# P4 Web security checklist

Reviewed: 2026-07-13. Scope: the single-owner Flutter Web session and its AI
Broker. This is an OWASP ASVS Level 1-style implementation checklist, not a
formal certification or penetration test.

## Access and sessions

- [x] Every AI route requires an allowlisted authenticated session.
- [x] Session identifiers are random, stored only as SHA-256 hashes server-side,
  and delivered in `HttpOnly`, `SameSite=Strict`, `Secure` production cookies.
- [x] POST routes require a per-session CSRF token; OAuth uses state, PKCE, and
  a separate short-lived `SameSite=Lax` correlation cookie.
- [x] Google identity tokens are signature-, issuer-, audience-, expiry-, email-
  and verification-checked. Passkey challenges are one-time and expire.
- [x] Production refuses to start with an empty email allowlist. Development
  login is hard-disabled in production.

## Secrets, AI abuse, and privacy

- [x] The provider key exists only in the broker environment/secret store and
  is never returned to Flutter, JavaScript, logs, cookies, or SQLite.
- [x] Text requests use a normalized schema and server-selected model allowlist;
  the browser cannot submit arbitrary provider payloads or endpoints.
- [x] Realtime returns only OpenAI's short-lived client credential; the standard
  key never enters the WebRTC client. The app limits interviews to 20 minutes.
- [x] Per-user burst throttling and atomic daily/monthly budget reservations run
  before the upstream call. Realtime uses a configurable conservative fixed
  reservation because media flows directly between browser and OpenAI.
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
  offline exercises remain available after the first authenticated load.

## Verification evidence

- [x] Broker tests cover unauthenticated access, CSRF, allowlisting, model
  restrictions, rate and budget limits, cookie flags, proxy normalization,
  Realtime minting, and security headers.
- [x] Flutter tests cover the broker gateway and ensure no API key appears in
  client payloads, along with the existing data, learning, and Realtime suite.
- [x] CI runs broker lint/tests and Flutter analyze/tests/production web build.
- [ ] After the first real deployment, enter the final URL in Mozilla
  Observatory and archive the report. External scanning cannot be completed
  before a domain and production service exist.
- [ ] Register the production Google OAuth callback and verify a real passkey,
  microphone permission, Realtime interview, and five-criterion report in a
  clean Chrome profile.
