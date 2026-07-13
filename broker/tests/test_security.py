import asyncio
import sqlite3

import pytest
from conftest import chat_body
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.config import Settings
from app.main import create_app
from app.middleware import RequestBodyLimitMiddleware
from app.security import MinuteRateLimiter, pseudonymous_user_id
from app.store import BrokerStore, PasskeyCredential


def test_ai_routes_require_authentication(client: TestClient) -> None:
    assert client.post("/api/chat", json=chat_body()).status_code == 401
    assert client.post("/api/realtime/session", json={}).status_code == 401
    assert client.post("/api/auth/passkeys/register/options").status_code == 401


def test_mutating_routes_require_csrf(client: TestClient) -> None:
    login = client.get("/auth/dev", params={"email": "owner@example.com"})
    assert login.status_code == 200
    assert client.post("/api/chat", json=chat_body()).status_code == 403
    assert client.post("/api/auth/logout").status_code == 403


def test_allowlist_blocks_unknown_accounts(client: TestClient) -> None:
    response = client.get("/auth/dev", params={"email": "attacker@example.com"})
    assert response.status_code == 403
    passkey = client.post(
        "/api/auth/passkeys/login/options",
        json={"email": "attacker@example.com"},
    )
    assert passkey.status_code == 404


def test_session_cookie_is_http_only_and_same_site_strict(client: TestClient) -> None:
    response = client.get("/auth/dev", params={"email": "owner@example.com"})
    cookie = response.headers["set-cookie"].lower()
    assert "httponly" in cookie
    assert "samesite=strict" in cookie


def test_security_headers_are_present(client: TestClient) -> None:
    response = client.get("/api/health")
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["cross-origin-opener-policy"] == "same-origin"
    assert response.headers["cross-origin-embedder-policy"] == "require-corp"
    assert response.headers["x-frame-options"] == "DENY"
    csp = response.headers["content-security-policy"]
    assert "default-src 'self'" in csp
    assert "connect-src 'self' https://api.openai.com" in csp
    assert response.headers["cache-control"] == "no-store"


def test_https_origin_enables_preloaded_hsts(settings: Settings) -> None:
    settings.public_origin = "https://sle-prep.example.com"
    app = create_app(settings)
    with TestClient(app) as client:
        response = client.get(
            "/api/health",
            headers={"host": "sle-prep.example.com"},
        )
    assert response.headers["strict-transport-security"] == (
        "max-age=63072000; includeSubDomains; preload"
    )


def test_comma_separated_environment_lists_are_parsed(monkeypatch) -> None:
    monkeypatch.setenv("ALLOWED_EMAILS", "Owner@Example.com, second@example.com")
    monkeypatch.setenv("ALLOWED_CHAT_MODELS", "gpt-5-mini, gpt-5")
    monkeypatch.setenv("TRUSTED_HOSTS", "*.onrender.com, sle-prep.example.com")
    parsed = Settings(_env_file=None)
    assert parsed.allowed_emails == {"owner@example.com", "second@example.com"}
    assert parsed.allowed_chat_models == {"gpt-5-mini", "gpt-5"}
    assert parsed.trusted_hosts == {"*.onrender.com", "sle-prep.example.com"}


def test_environment_is_normalized_and_unknown_values_fail() -> None:
    parsed = Settings(environment=" Production ", public_origin="https://example.com")
    assert parsed.environment == "production"
    assert parsed.secure_cookies is True
    with pytest.raises(ValidationError, match="environment"):
        Settings(environment="prodution")


def test_authenticated_session_exposes_csrf_not_cookie_value(authenticated) -> None:
    client, csrf = authenticated
    response = client.get("/api/auth/session")
    assert response.json()["authenticated"] is True
    assert response.json()["csrfToken"] == csrf
    assert response.json()["userId"].startswith("sle_")
    assert "test-provider-key" not in response.text


def test_passkey_registration_options_are_bound_to_owner(authenticated) -> None:
    client, csrf = authenticated
    response = client.post(
        "/api/auth/passkeys/register/options",
        headers={"x-csrf-token": csrf},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["challengeId"]
    assert body["publicKey"]["rp"]["id"] == "localhost"
    assert body["publicKey"]["user"]["name"] == "owner@example.com"


def test_fresh_session_only_advertises_available_login_methods(client: TestClient) -> None:
    response = client.get("/api/auth/session")
    assert response.json()["passkeysEnabled"] is False
    assert response.json()["googleEnabled"] is False


def test_user_identifier_is_stable_private_and_distinct(settings: Settings) -> None:
    first = pseudonymous_user_id(settings, "Owner@Example.com")
    repeated = pseudonymous_user_id(settings, "owner@example.com")
    second = pseudonymous_user_id(settings, "second@example.com")
    assert first == repeated
    assert first != second
    assert "owner" not in first
    assert "example" not in first


def test_rate_limiter_identity_storage_is_bounded() -> None:
    limiter = MinuteRateLimiter(10, max_identities=100)
    for index in range(10_000):
        limiter.check(f"attacker-{index}@example.com")
    assert limiter.identity_count == 100


def test_readiness_reports_storage_failure(client: TestClient, monkeypatch) -> None:
    def fail() -> None:
        raise sqlite3.OperationalError("disk is read-only")

    monkeypatch.setattr(client.app.state.store, "check_ready", fail)
    assert client.get("/api/live").status_code == 200
    response = client.get("/api/ready")
    assert response.status_code == 503
    assert "disk is read-only" not in response.text


def test_invalid_production_origin_is_rejected(tmp_path) -> None:
    with pytest.raises(ValidationError, match="HTTPS"):
        Settings(
            environment="production",
            public_origin="http://example.com",
            database_path=tmp_path / "invalid.db",
        )

    with pytest.raises(ValidationError, match="invalid port"):
        Settings(public_origin="https://example.com:notaport")


def test_production_rejects_non_tls_or_modified_openai_endpoint() -> None:
    for endpoint in (
        "http://api.openai.com/v1",
        "https://api.openai.com:444/v1",
        "https://api.openai.com/v1?redirect=example.com",
        "https://api.openai.com/other",
    ):
        with pytest.raises(ValidationError, match="OPENAI_BASE_URL"):
            Settings(
                environment="production",
                public_origin="https://example.com",
                openai_base_url=endpoint,
            )


def test_fresh_production_database_requires_bootstrap_auth(settings: Settings) -> None:
    settings.environment = "production"
    settings.public_origin = "https://sle-prep.example.com"
    settings.identifier_secret = "x" * 32
    with pytest.raises(RuntimeError, match="bootstrap"):
        create_app(settings)


def test_stale_disallowed_passkey_cannot_satisfy_production_bootstrap(
    settings: Settings,
) -> None:
    store = BrokerStore(settings.database_path)
    store.save_passkey(
        "former-owner@example.com",
        PasskeyCredential(b"id", b"public-key", 0, []),
    )
    store.close()
    settings.environment = "production"
    settings.public_origin = "https://sle-prep.example.com"
    settings.identifier_secret = "x" * 32
    with pytest.raises(RuntimeError, match="bootstrap"):
        create_app(settings)


def test_production_requires_a_finalized_web_build(settings: Settings, tmp_path) -> None:
    settings.environment = "production"
    settings.public_origin = "https://sle-prep.example.com"
    settings.identifier_secret = "x" * 32
    settings.google_client_id = "client"
    settings.google_client_secret = "secret"
    settings.static_dir = tmp_path / "missing-web-build"
    with pytest.raises(RuntimeError, match="STATIC_DIR"):
        create_app(settings)


def test_declared_oversized_body_is_rejected_before_auth(client: TestClient) -> None:
    response = client.post(
        "/api/chat",
        content=b"{}",
        headers={"content-length": "300000"},
    )
    assert response.status_code == 413


def test_chunked_oversized_body_is_rejected() -> None:
    sent: list[dict] = []
    chunks = iter(
        [
            {"type": "http.request", "body": b"123", "more_body": True},
            {"type": "http.request", "body": b"456", "more_body": False},
        ]
    )

    async def receive() -> dict:
        return next(chunks)

    async def send(message: dict) -> None:
        sent.append(message)

    async def consume_body(scope, receive, send) -> None:
        while (await receive()).get("more_body", False):
            pass
        await send({"type": "http.response.start", "status": 204, "headers": []})
        await send({"type": "http.response.body", "body": b""})

    middleware = RequestBodyLimitMiddleware(consume_body, max_bytes=4)
    asyncio.run(
        middleware(
            {"type": "http", "method": "POST", "path": "/", "headers": []},
            receive,
            send,
        )
    )
    assert sent[0]["status"] == 413
