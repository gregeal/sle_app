# SLE Prep AI Broker

The broker is the security boundary for the public Flutter Web build. It owns
the long-lived OpenAI key, enforces the email allowlist, rate and reservation caps,
and gives the browser only an HttpOnly session cookie or a short-lived OpenAI
Realtime client secret.

## Local development

```powershell
cd broker
Copy-Item .env.example .env
# Set ALLOWED_EMAILS, OPENAI_API_KEY, a stable IDENTIFIER_SECRET,
# and DEV_LOGIN_ENABLED=true in .env.
uv sync --dev
uv run uvicorn app.asgi:app --reload --port 8000
```

Generate `IDENTIFIER_SECRET` once and copy the result into `.env`:

```powershell
uv run python -c "import secrets; print(secrets.token_urlsafe(48))"
```

The value must be at least 32 random characters in production. It HMAC-derives
the opaque user ID returned to Flutter and the privacy-preserving OpenAI safety
identifier. Keep it stable and backed up: changing it changes each user's
browser-database namespace, making prior local progress appear empty.

For local-only bootstrap, open
`http://localhost:8000/auth/dev?email=you@example.com`. The route is unavailable
when `ENVIRONMENT=production`. Production uses Google OAuth once, then the
signed-in owner can register a phishing-resistant passkey in the app.

## Production bootstrap and required configuration

Production fails closed unless all of the following are true:

- `PUBLIC_ORIGIN` is one exact HTTPS origin and `ALLOWED_EMAILS` is non-empty.
- `TRUSTED_HOSTS` contains every accepted hostname. For a Render custom domain,
  include that hostname as well as `*.onrender.com`; do not use a blanket `*`.
- `IDENTIFIER_SECRET` is stable, random, and at least 32 characters.
- `OPENAI_API_KEY` is present and `OPENAI_BASE_URL` is the official
  `https://api.openai.com/v1` endpoint.
- A fresh database has both `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`, so
  an allowlisted owner can bootstrap the first passkey. Google OAuth can be
  removed only while a persisted passkey belongs to an email still present in
  `ALLOWED_EMAILS`, although retaining Google provides an account-recovery route.

Register `${PUBLIC_ORIGIN}/auth/google/callback` exactly in Google Cloud. The
origin must also match the host used by the browser for cookies and WebAuthn.
Never enable `DEV_LOGIN_ENABLED` in production.

The complete environment reference is in [`.env.example`](.env.example). In
particular:

- `REQUESTS_PER_MINUTE` and `AUTH_REQUESTS_PER_MINUTE` bound AI and auth bursts;
  `RATE_LIMIT_MAX_IDENTITIES` bounds in-memory limiter state, and
  `MAX_REQUEST_BODY_BYTES` rejects oversized fixed or chunked request bodies.
- `DAILY_BUDGET_USD` and `MONTHLY_BUDGET_USD` gate reservations. Current model
  prices must be supplied through `CHAT_INPUT_USD_PER_MILLION` and
  `CHAT_OUTPUT_USD_PER_MILLION` rather than assumed from repository defaults.
- `REALTIME_SESSION_RESERVE_USD` is a conservative quota reservation only.
  Because browser audio flows directly to OpenAI, it is neither actual-usage
  accounting nor a guaranteed maximum charge. Configure OpenAI project-level
  limits/alerts as the provider-side backstop.
- `CLEANUP_INTERVAL_MINUTES` controls maintenance cadence.
  `RESERVATION_STALE_MINUTES` settles abandoned reservations at their reserved
  amount, while `AUDIT_RETENTION_DAYS` and `USAGE_RETENTION_DAYS` bound metadata
  retention. Expired sessions and WebAuthn challenges are also removed.

The broker uses one SQLite database and process-local limiters. Keep a single
service instance; move these controls to a shared transactional store before
horizontal scaling.

## Health and operations

- `GET /api/live` reports process liveness without touching storage.
- `GET /api/ready` performs a transactional database write/read/rollback probe
  and is the deployment health-check endpoint.
- `GET /api/health` is a compatibility alias of readiness.

API and auth responses are `no-store`; application entry points are
`no-cache`; static assets receive a bounded cache policy. The Flutter service
worker separately refuses to intercept `/api/*` and `/auth/*`.
Successful responses include `X-Request-ID`, and privacy-safe structured logs
record route, status, and latency without prompts, transcripts, keys, or email.

Run the broker checks with:

```powershell
uv sync --frozen --dev
uv run --frozen ruff check app tests
uv run --frozen pytest
```

Test counts are intentionally not duplicated here; use the command output or
the latest CI run as the source of truth. A real Google OAuth/passkey flow,
paid OpenAI text/Realtime requests, microphone routing, and external security
header scan remain deployment smoke tests that require owner-managed secrets
and infrastructure.

Never put `OPENAI_API_KEY` in Flutter build arguments, JavaScript, repository
files, or client-readable storage. Configure it only in the deployment secret
store. The SQLite database contains session hashes, passkey public keys, usage
amounts, and content-free audit events; it does not contain prompts,
transcripts, provider tokens, or API keys.
