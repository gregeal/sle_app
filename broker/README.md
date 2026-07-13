# SLE Prep AI Broker

The broker is the security boundary for the public Flutter Web build. It owns
the long-lived OpenAI key, enforces the email allowlist, rate and spend caps,
and gives the browser only an HttpOnly session cookie or a short-lived OpenAI
Realtime client secret.

## Local development

```powershell
cd broker
Copy-Item .env.example .env
# Set ALLOWED_EMAILS, OPENAI_API_KEY and DEV_LOGIN_ENABLED=true in .env.
uv sync --dev
uv run uvicorn app.asgi:app --reload --port 8000
```

For local-only bootstrap, open
`http://localhost:8000/auth/dev?email=you@example.com`. The route is unavailable
when `ENVIRONMENT=production`. Production uses Google OAuth once, then the
signed-in owner can register a phishing-resistant passkey in the app.

Run the broker checks with `uv run pytest` and `uv run ruff check app tests`.

Never put `OPENAI_API_KEY` in Flutter build arguments, JavaScript, repository
files, or client-readable storage. Configure it only in the deployment secret
store. The SQLite database contains session hashes, passkey public keys, usage
amounts, and content-free audit events; it does not contain prompts,
transcripts, provider tokens, or API keys.
