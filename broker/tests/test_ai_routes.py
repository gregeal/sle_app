import json
import sqlite3

import httpx
from conftest import chat_body
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from app.openai_service import estimated_chat_cost_micros
from app.schemas import ChatRequest


def test_chat_proxy_uses_server_key_and_model(
    authenticated,
    upstream_requests,
) -> None:
    client, csrf = authenticated
    response = client.post(
        "/api/chat",
        headers={"x-csrf-token": csrf},
        json=chat_body(),
    )
    assert response.status_code == 200
    assert response.json() == {"text": "Réponse test"}
    request = upstream_requests[0]
    assert request.headers["authorization"] == "Bearer test-provider-key"
    payload = json.loads(request.content)
    assert payload["model"] == "gpt-test"
    assert payload["store"] is False
    assert payload["safety_identifier"].startswith("sle_")
    assert "owner@example.com" not in payload["safety_identifier"]
    assert "api_key" not in payload


def test_realtime_route_returns_only_ephemeral_secret(
    authenticated,
    upstream_requests,
) -> None:
    client, csrf = authenticated
    response = client.post(
        "/api/realtime/session",
        headers={"x-csrf-token": csrf},
        json={"model": "gpt-realtime", "voice": "marin"},
    )
    assert response.status_code == 200
    assert response.json() == {"value": "ek_test_short_lived"}
    assert "test-provider-key" not in response.text
    payload = json.loads(upstream_requests[-1].content)
    assert payload["session"]["audio"]["input"]["turn_detection"]["type"] == "semantic_vad"
    safety_id = upstream_requests[-1].headers["openai-safety-identifier"]
    assert safety_id.startswith("sle_")
    assert "owner@example.com" not in safety_id


def test_model_allowlist_is_enforced_before_proxy(settings: Settings, upstream_requests) -> None:
    settings.chat_model = "not-allowed"
    app = create_app(settings)
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=chat_body(),
        )
    assert response.status_code == 503


def test_daily_budget_blocks_request_before_openai(settings: Settings) -> None:
    settings.daily_budget_usd = 0.000001
    settings.monthly_budget_usd = 0.000001
    app = create_app(settings)
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=chat_body(max_tokens=2000),
        )
    assert response.status_code == 429
    assert "plafond" in response.json()["detail"].lower()
    with sqlite3.connect(settings.database_path) as connection:
        audits = connection.execute(
            "SELECT outcome, status_code FROM audit_events WHERE route = '/api/chat'"
        ).fetchall()
    assert audits == [("budget-exceeded", 429)]


def test_broker_output_cap_supports_largest_app_generator(
    authenticated,
    upstream_requests,
) -> None:
    client, csrf = authenticated
    response = client.post(
        "/api/chat",
        headers={"x-csrf-token": csrf},
        json=chat_body(max_tokens=4000),
    )
    assert response.status_code == 200
    payload = json.loads(upstream_requests[-1].content)
    assert payload["max_completion_tokens"] == 4000


def test_rate_limit_blocks_burst(settings: Settings) -> None:
    settings.requests_per_minute = 1
    settings.openai_api_key = ""
    app = create_app(settings)
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        headers = {"x-csrf-token": login.json()["csrfToken"]}
        first = client.post("/api/realtime/session", headers=headers, json={})
        second = client.post("/api/realtime/session", headers=headers, json={})
    # The first reaches an unconfigured/real upstream in this isolated app, but
    # it still consumes the limiter slot before the second is rejected locally.
    assert first.status_code == 503
    assert second.status_code == 429


def test_missing_upstream_usage_keeps_conservative_reservation(settings: Settings) -> None:
    async def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={"choices": [{"message": {"content": "RÃ©ponse sans usage"}}]},
        )

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    app = create_app(settings, openai_client=upstream)
    body = chat_body()
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=body,
        )
    assert response.status_code == 200
    with sqlite3.connect(settings.database_path) as connection:
        charged = connection.execute(
            "SELECT cost_micros FROM usage_reservations WHERE status = 'settled'"
        ).fetchone()[0]
    assert charged == estimated_chat_cost_micros(ChatRequest(**body), settings)


def test_transient_upstream_failure_is_retried_once(settings: Settings) -> None:
    calls = 0

    async def handler(_: httpx.Request) -> httpx.Response:
        nonlocal calls
        calls += 1
        if calls == 1:
            return httpx.Response(503, json={"error": {"message": "internal detail"}})
        return httpx.Response(
            200,
            json={
                "choices": [{"message": {"content": "Réponse après reprise"}}],
                "usage": {"prompt_tokens": 2, "completion_tokens": 3},
            },
        )

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    app = create_app(settings, openai_client=upstream)
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=chat_body(),
        )
    assert response.status_code == 200
    assert calls == 2


def test_unexpected_upstream_error_releases_budget_reservation(settings: Settings) -> None:
    async def handler(_: httpx.Request) -> httpx.Response:
        raise RuntimeError("unexpected provider adapter failure")

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    app = create_app(settings, openai_client=upstream)
    with TestClient(app, raise_server_exceptions=False) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=chat_body(),
        )
    assert response.status_code == 500
    with sqlite3.connect(settings.database_path) as connection:
        row = connection.execute(
            "SELECT cost_micros, status FROM usage_reservations ORDER BY created_at DESC"
        ).fetchone()
    assert row == (0, "released")


def test_upstream_error_detail_is_not_exposed(settings: Settings) -> None:
    async def handler(_: httpx.Request) -> httpx.Response:
        return httpx.Response(
            401,
            json={"error": {"message": "org-secret sk-example must never leak"}},
        )

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    app = create_app(settings, openai_client=upstream)
    with TestClient(app) as client:
        login = client.get("/auth/dev", params={"email": "owner@example.com"})
        response = client.post(
            "/api/chat",
            headers={"x-csrf-token": login.json()["csrfToken"]},
            json=chat_body(),
        )
    assert response.status_code == 401
    assert "org-secret" not in response.text
    assert "sk-example" not in response.text
