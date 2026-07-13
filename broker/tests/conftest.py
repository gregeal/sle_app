from __future__ import annotations

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def settings(tmp_path) -> Settings:
    return Settings(
        environment="test",
        public_origin="http://localhost",
        database_path=tmp_path / "broker.db",
        allowed_emails={"owner@example.com"},
        dev_login_enabled=True,
        openai_api_key="test-provider-key",
        chat_model="gpt-test",
        allowed_chat_models={"gpt-test"},
        realtime_model="gpt-realtime",
        allowed_realtime_models={"gpt-realtime"},
        identifier_secret="test-identifier-secret-that-is-long-enough",
        openai_retry_base_seconds=0,
        daily_budget_usd=10,
        monthly_budget_usd=100,
    )


@pytest.fixture
def upstream_requests() -> list[httpx.Request]:
    return []


@pytest.fixture
def client(settings: Settings, upstream_requests: list[httpx.Request]):
    async def handler(request: httpx.Request) -> httpx.Response:
        upstream_requests.append(request)
        if request.url.path.endswith("/chat/completions"):
            return httpx.Response(
                200,
                json={
                    "choices": [{"message": {"content": "Réponse test"}}],
                    "usage": {"prompt_tokens": 25, "completion_tokens": 10},
                },
            )
        if request.url.path.endswith("/realtime/client_secrets"):
            return httpx.Response(200, json={"value": "ek_test_short_lived"})
        return httpx.Response(404, json={"error": {"message": "not found"}})

    upstream = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    app = create_app(settings, openai_client=upstream)
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def authenticated(client: TestClient) -> tuple[TestClient, str]:
    response = client.get("/auth/dev", params={"email": "owner@example.com"})
    assert response.status_code == 200
    return client, response.json()["csrfToken"]


def chat_body(**updates) -> dict:
    body = {
        "system": "Réponds en français.",
        "user": "Explique le subjonctif.",
        "temperature": 0.3,
        "max_tokens": 200,
    }
    body.update(updates)
    return body
