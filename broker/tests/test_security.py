from conftest import chat_body
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


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


def test_authenticated_session_exposes_csrf_not_cookie_value(authenticated) -> None:
    client, csrf = authenticated
    response = client.get("/api/auth/session")
    assert response.json()["authenticated"] is True
    assert response.json()["csrfToken"] == csrf
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
