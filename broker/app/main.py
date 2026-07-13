from __future__ import annotations

import json
import logging
import secrets
import sqlite3
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Annotated
from urllib.parse import urlencode, urlparse

import httpx
import jwt
from fastapi import Depends, FastAPI, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from jwt.algorithms import RSAAlgorithm
from starlette.middleware.gzip import GZipMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware

from .config import Settings, get_settings
from .middleware import RequestBodyLimitMiddleware
from .openai_service import (
    OpenAiService,
    actual_chat_cost_micros,
    estimated_chat_cost_micros,
)
from .passkeys import (
    authentication_options,
    finish_authentication,
    finish_registration,
    registration_options,
)
from .schemas import (
    ChatRequest,
    PasskeyFinishRequest,
    PasskeyLoginOptionsRequest,
    RealtimeSessionRequest,
)
from .security import (
    MinuteRateLimiter,
    allowed_email,
    delete_session_cookie,
    oauth_pkce,
    pseudonymous_user_id,
    require_csrf,
    set_session_cookie,
)
from .store import BrokerStore, Session

CsrfSession = Annotated[Session, Depends(require_csrf)]
logger = logging.getLogger("sle_prep.broker")


def create_app(
    settings: Settings | None = None,
    *,
    openai_client: httpx.AsyncClient | None = None,
) -> FastAPI:
    settings = settings or get_settings()
    store = BrokerStore(settings.database_path)
    if settings.environment == "production":
        if not settings.allowed_emails:
            store.close()
            raise RuntimeError("ALLOWED_EMAILS must not be empty in production")
        if (
            len(settings.identifier_secret) < 32
            or settings.identifier_secret == "development-only-identifier-secret"
        ):
            store.close()
            raise RuntimeError("IDENTIFIER_SECRET must be a stable random secret in production")
        if not settings.openai_api_key:
            store.close()
            raise RuntimeError("OPENAI_API_KEY must not be empty in production")
        if not settings.official_openai_endpoint:
            store.close()
            raise RuntimeError("OPENAI_BASE_URL must use the official OpenAI API in production")
        if not settings.google_enabled and not store.has_passkey_for_any(settings.allowed_emails):
            store.close()
            raise RuntimeError(
                "A fresh production database requires Google OAuth to bootstrap the first passkey"
            )
        static_dir = Path(settings.static_dir) if settings.static_dir is not None else None
        required_web_files = ("index.html", "main.dart.js", "sle_prep_sw.js")
        if static_dir is None or not static_dir.is_dir() or any(
            not (static_dir / name).is_file() for name in required_web_files
        ):
            store.close()
            raise RuntimeError(
                "STATIC_DIR must contain the finalized Flutter web build in production"
            )
        if "__SLE_PREP_BUILD_ID__" in (static_dir / "sle_prep_sw.js").read_text(
            encoding="utf-8"
        ):
            store.close()
            raise RuntimeError("The production service worker has not been finalized")

    openai = OpenAiService(settings, openai_client)
    rate_limiter = MinuteRateLimiter(
        settings.requests_per_minute,
        max_identities=settings.rate_limit_max_identities,
    )
    auth_rate_limiter = MinuteRateLimiter(
        settings.auth_requests_per_minute,
        max_identities=settings.rate_limit_max_identities,
        detail="Trop de tentatives de connexion. Attendez une minute puis réessayez.",
    )
    last_cleanup = 0.0

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        store.cleanup(
            reservation_stale_minutes=settings.reservation_stale_minutes,
            audit_retention_days=settings.audit_retention_days,
            usage_retention_days=settings.usage_retention_days,
        )
        yield
        await openai.close()
        store.close()

    app = FastAPI(
        title="SLE Prep AI Broker",
        docs_url=None if settings.environment == "production" else "/docs",
        redoc_url=None,
        openapi_url=None if settings.environment == "production" else "/openapi.json",
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.store = store
    app.state.openai = openai
    app.state.rate_limiter = rate_limiter
    app.state.auth_rate_limiter = auth_rate_limiter

    host = urlparse(settings.public_origin).hostname or "localhost"
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=[
            host,
            "localhost",
            "127.0.0.1",
            "testserver",
            *sorted(settings.trusted_hosts),
        ],
    )
    app.add_middleware(GZipMiddleware, minimum_size=1_024)
    app.add_middleware(
        RequestBodyLimitMiddleware,
        max_bytes=settings.max_request_body_bytes,
    )

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        nonlocal last_cleanup
        started = time.perf_counter()
        request_id = request.headers.get("x-request-id", "")
        if (
            not request_id
            or len(request_id) > 64
            or not all(char.isalnum() or char in "-_" for char in request_id)
        ):
            request_id = secrets.token_urlsafe(12)

        now = time.monotonic()
        if now - last_cleanup >= settings.cleanup_interval_minutes * 60:
            last_cleanup = now
            try:
                store.cleanup(
                    reservation_stale_minutes=settings.reservation_stale_minutes,
                    audit_retention_days=settings.audit_retention_days,
                    usage_retention_days=settings.usage_retention_days,
                )
            except sqlite3.Error:
                logger.exception("broker metadata cleanup failed")

        try:
            response = await call_next(request)
        except Exception:
            logger.exception(
                json.dumps(
                    {
                        "event": "request",
                        "request_id": request_id,
                        "method": request.method,
                        "path": request.url.path,
                        "status": 500,
                        "duration_ms": round((time.perf_counter() - started) * 1_000, 1),
                    }
                )
            )
            raise
        response.headers["X-Request-ID"] = request_id
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; base-uri 'self'; object-src 'none'; "
            "frame-ancestors 'none'; img-src 'self' data: blob:; "
            "font-src 'self' data:; style-src 'self' 'unsafe-inline'; "
            "script-src 'self' 'wasm-unsafe-eval'; "
            "connect-src 'self' https://api.openai.com; "
            "media-src 'self' blob:; worker-src 'self' blob:; "
            "manifest-src 'self'; form-action 'self' https://accounts.google.com"
        )
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
        response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "same-origin"
        response.headers["Permissions-Policy"] = "microphone=(self), camera=(), geolocation=()"
        response.headers["X-Frame-Options"] = "DENY"
        if settings.secure_cookies:
            response.headers["Strict-Transport-Security"] = (
                "max-age=63072000; includeSubDomains; preload"
            )
        if request.url.path.startswith(("/api/", "/auth/")):
            response.headers["Cache-Control"] = "no-store"
        elif request.url.path in {
            "/",
            "/index.html",
            "/flutter_bootstrap.js",
            "/sle_prep_sw.js",
            "/manifest.json",
        }:
            response.headers["Cache-Control"] = "no-cache"
        else:
            response.headers["Cache-Control"] = (
                "public, max-age=86400, stale-while-revalidate=604800"
            )
        logger.info(
            json.dumps(
                {
                    "event": "request",
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status": response.status_code,
                    "duration_ms": round((time.perf_counter() - started) * 1_000, 1),
                }
            )
        )
        return response

    @app.get("/api/live")
    async def live() -> dict[str, str]:
        return {"status": "ok"}

    async def _ready() -> dict[str, str]:
        try:
            store.check_ready()
        except sqlite3.Error as error:
            raise HTTPException(status_code=503, detail="Le stockage n'est pas prêt.") from error
        return {"status": "ready"}

    app.add_api_route("/api/ready", _ready, methods=["GET"])
    # Backwards-compatible readiness alias used by older deployments.
    app.add_api_route("/api/health", _ready, methods=["GET"])

    @app.get("/api/auth/session")
    async def auth_session(request: Request) -> dict:
        session = store.get_session(request.cookies.get(settings.session_cookie))
        if session is None or not allowed_email(settings, session.email):
            return {
                "authenticated": False,
                "googleEnabled": settings.google_enabled,
                "passkeysEnabled": store.has_passkey_for_any(settings.allowed_emails),
            }
        return {
            "authenticated": True,
            "email": session.email,
            "userId": pseudonymous_user_id(settings, session.email),
            "csrfToken": session.csrf_token,
            "googleEnabled": settings.google_enabled,
            "passkeysEnabled": True,
            "passkeyCount": len(store.passkeys_for_email(session.email)),
        }

    @app.post("/api/auth/logout")
    async def logout(request: Request, session: CsrfSession) -> Response:
        store.delete_session(request.cookies.get(settings.session_cookie))
        response = Response(status_code=204)
        delete_session_cookie(response, settings)
        store.audit(session.email, "/api/auth/logout", "ok", 204)
        return response

    @app.get("/auth/google/start")
    async def google_start(request: Request) -> Response:
        auth_rate_limiter.check(f"google-start:{_client_identity(request)}")
        if not settings.google_enabled:
            raise HTTPException(status_code=503, detail="Google OAuth n'est pas configuré.")
        verifier, code_challenge = oauth_pkce()
        nonce = secrets.token_urlsafe(24)
        state_value = store.put_challenge(
            kind="google-oauth",
            verifier=verifier,
            challenge=nonce.encode("utf-8"),
        )
        redirect_uri = f"{settings.public_origin}/auth/google/callback"
        params = {
            "client_id": settings.google_client_id,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": "openid email profile",
            "state": state_value,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
            "prompt": "select_account",
            "nonce": nonce,
        }
        response = RedirectResponse(
            f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}",
            status_code=302,
        )
        response.set_cookie(
            "sle_oauth_state",
            state_value,
            max_age=300,
            httponly=True,
            secure=settings.secure_cookies,
            samesite="lax",
            path="/auth/google/callback",
        )
        return response

    @app.get("/auth/google/callback")
    async def google_callback(request: Request, code: str, state: str) -> Response:
        auth_rate_limiter.check(f"google-callback:{_client_identity(request)}")
        cookie_state = request.cookies.get("sle_oauth_state", "")
        if not cookie_state or not secrets.compare_digest(cookie_state, state):
            raise HTTPException(status_code=400, detail="État OAuth invalide.")
        row = store.consume_challenge(state, "google-oauth")
        if row is None:
            raise HTTPException(status_code=400, detail="Ouverture de session expirée.")
        redirect_uri = f"{settings.public_origin}/auth/google/callback"
        async with httpx.AsyncClient(timeout=20) as client:
            token_response = await client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "code": code,
                    "client_id": settings.google_client_id,
                    "client_secret": settings.google_client_secret,
                    "redirect_uri": redirect_uri,
                    "grant_type": "authorization_code",
                    "code_verifier": row["verifier"],
                },
            )
            if token_response.status_code != 200:
                raise HTTPException(status_code=401, detail="Google a refusé la connexion.")
            id_token = token_response.json().get("id_token")
            if not isinstance(id_token, str):
                raise HTTPException(status_code=401, detail="Jeton Google manquant.")
            try:
                email = await _verify_google_id_token(
                    client,
                    id_token,
                    settings.google_client_id,
                    expected_nonce=bytes(row["challenge"]).decode("utf-8"),
                )
            except (httpx.HTTPError, jwt.PyJWTError, ValueError) as error:
                raise HTTPException(
                    status_code=401,
                    detail="Le jeton d’identité Google n’a pas pu être vérifié.",
                ) from error
        if not allowed_email(settings, email):
            store.audit(email, "/auth/google/callback", "not-allowlisted", 403)
            raise HTTPException(status_code=403, detail="Ce compte n'est pas autorisé.")
        raw_token, _ = store.create_session(email, settings.session_hours)
        response = RedirectResponse("/", status_code=303)
        set_session_cookie(response, settings, raw_token)
        response.delete_cookie("sle_oauth_state", path="/auth/google/callback")
        store.audit(email, "/auth/google/callback", "ok", 303)
        return response

    @app.get("/auth/dev")
    async def dev_login(email: str) -> Response:
        if settings.environment == "production" or not settings.dev_login_enabled:
            raise HTTPException(status_code=404)
        if not allowed_email(settings, email):
            raise HTTPException(status_code=403, detail="Compte non autorisé.")
        raw_token, session = store.create_session(email, settings.session_hours)
        response = JSONResponse({"authenticated": True, "csrfToken": session.csrf_token})
        set_session_cookie(response, settings, raw_token)
        return response

    @app.post("/api/auth/passkeys/register/options")
    async def passkey_register_options(session: CsrfSession) -> dict:
        auth_rate_limiter.check(f"passkey-register:{session.email}")
        return registration_options(store, settings, session.email)

    @app.post("/api/auth/passkeys/register/finish")
    async def passkey_register_finish(
        body: PasskeyFinishRequest,
        session: CsrfSession,
    ) -> dict[str, bool]:
        auth_rate_limiter.check(f"passkey-register:{session.email}")
        try:
            finish_registration(
                store,
                settings,
                session.email,
                body.challenge_id,
                body.credential,
            )
        except Exception as error:
            store.audit(session.email, "/api/auth/passkeys/register/finish", "invalid", 400)
            raise HTTPException(status_code=400, detail="Passkey invalide ou expirée.") from error
        store.audit(session.email, "/api/auth/passkeys/register/finish", "ok", 200)
        return {"registered": True}

    @app.post("/api/auth/passkeys/login/options")
    async def passkey_login_options(
        body: PasskeyLoginOptionsRequest,
        request: Request,
    ) -> dict:
        email = body.email.lower()
        auth_rate_limiter.check(f"passkey-options:{_client_identity(request)}")
        if not allowed_email(settings, email):
            # Deliberately match the no-credential response to limit account discovery.
            raise HTTPException(status_code=404, detail="Aucune passkey disponible.")
        try:
            return authentication_options(store, settings, email)
        except LookupError as error:
            raise HTTPException(status_code=404, detail="Aucune passkey disponible.") from error

    @app.post("/api/auth/passkeys/login/finish")
    async def passkey_login_finish(body: PasskeyFinishRequest, request: Request) -> Response:
        auth_rate_limiter.check(f"passkey-finish:{_client_identity(request)}")
        try:
            email = finish_authentication(
                store,
                settings,
                body.challenge_id,
                body.credential,
            )
        except Exception as error:
            raise HTTPException(status_code=400, detail="Passkey invalide ou expirée.") from error
        if not allowed_email(settings, email):
            raise HTTPException(status_code=403, detail="Compte non autorisé.")
        raw_token, session = store.create_session(email, settings.session_hours)
        response = JSONResponse(
            {"authenticated": True, "email": email, "csrfToken": session.csrf_token}
        )
        set_session_cookie(response, settings, raw_token)
        store.audit(email, "/api/auth/passkeys/login/finish", "ok", 200)
        return response

    @app.post("/api/chat")
    async def chat(body: ChatRequest, session: CsrfSession) -> dict[str, str]:
        rate_limiter.check(session.email)
        if settings.chat_model.lower() not in settings.allowed_chat_models:
            raise HTTPException(
                status_code=503,
                detail="Le modèle texte du serveur n'est pas autorisé.",
            )
        estimated = estimated_chat_cost_micros(body, settings)
        try:
            reservation_id = _reserve(
                store,
                settings,
                session.email,
                "/api/chat",
                estimated,
            )
        except HTTPException:
            raise
        except BaseException:
            store.audit(session.email, "/api/chat", "internal-error", 500)
            raise
        try:
            with _UsageReservation(
                store,
                reservation_id,
            ) as reservation:
                result = await openai.chat(
                    body,
                    safety_identifier=pseudonymous_user_id(settings, session.email),
                )
                actual_cost = actual_chat_cost_micros(result, settings)
                if result.input_tokens == 0 and result.output_tokens == 0:
                    # Do not turn missing provider usage into a near-zero
                    # charge that bypasses the configured budget ceiling.
                    actual_cost = estimated
                reservation.settle(actual_cost)
        except HTTPException as error:
            store.audit(session.email, "/api/chat", "upstream-error", error.status_code)
            raise
        except BaseException:
            store.audit(session.email, "/api/chat", "internal-error", 500)
            raise
        store.audit(session.email, "/api/chat", "ok", 200)
        return {"text": result.text}

    @app.post("/api/realtime/session")
    async def realtime_session(
        body: RealtimeSessionRequest,
        session: CsrfSession,
    ) -> dict[str, str]:
        rate_limiter.check(session.email)
        reserve_micros = max(1, round(settings.realtime_session_reserve_usd * 1_000_000))
        try:
            reservation_id = _reserve(
                store,
                settings,
                session.email,
                "/api/realtime/session",
                reserve_micros,
            )
        except HTTPException:
            raise
        except BaseException:
            store.audit(session.email, "/api/realtime/session", "internal-error", 500)
            raise
        try:
            with _UsageReservation(
                store,
                reservation_id,
            ) as reservation:
                value = await openai.realtime_secret(
                    body,
                    safety_identifier=pseudonymous_user_id(settings, session.email),
                )
                reservation.settle(reserve_micros)
        except HTTPException as error:
            store.audit(session.email, "/api/realtime/session", "upstream-error", error.status_code)
            raise
        except BaseException:
            store.audit(session.email, "/api/realtime/session", "internal-error", 500)
            raise
        store.audit(session.email, "/api/realtime/session", "ok", 200)
        return {"value": value}

    static_dir = settings.static_dir
    if static_dir is not None and Path(static_dir).is_dir():
        app.mount("/", StaticFiles(directory=static_dir, html=True), name="web")
    return app


class _UsageReservation:
    """Always releases an unsettled reservation, including on cancellation."""

    def __init__(self, store: BrokerStore, request_id: str):
        self._store = store
        self._request_id = request_id
        self._closed = False

    def __enter__(self) -> _UsageReservation:
        return self

    def settle(self, cost_micros: int) -> None:
        self._store.settle_usage(self._request_id, cost_micros)
        self._closed = True

    def __exit__(self, _type, _value, _traceback) -> None:
        if not self._closed:
            self._store.settle_usage(self._request_id, 0, released=True)
            self._closed = True


def _client_identity(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _reserve(
    store: BrokerStore,
    settings: Settings,
    email: str,
    route: str,
    cost_micros: int,
) -> str:
    reservation = store.reserve_usage(
        email=email,
        route=route,
        cost_micros=cost_micros,
        daily_limit_micros=round(settings.daily_budget_usd * 1_000_000),
        monthly_limit_micros=round(settings.monthly_budget_usd * 1_000_000),
    )
    if reservation is None:
        store.audit(email, route, "budget-exceeded", 429)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Le plafond de dépenses IA est atteint. Réessayez après son renouvellement.",
        )
    return reservation


async def _verify_google_id_token(
    client: httpx.AsyncClient,
    id_token: str,
    audience: str,
    *,
    expected_nonce: str,
) -> str:
    jwks_response = await client.get("https://www.googleapis.com/oauth2/v3/certs")
    jwks_response.raise_for_status()
    header = jwt.get_unverified_header(id_token)
    key_data = next(
        (
            key
            for key in jwks_response.json().get("keys", [])
            if key.get("kid") == header.get("kid")
        ),
        None,
    )
    if key_data is None:
        raise HTTPException(status_code=401, detail="Signature Google inconnue.")
    public_key = RSAAlgorithm.from_jwk(json.dumps(key_data))
    payload = jwt.decode(id_token, public_key, algorithms=["RS256"], audience=audience)
    if payload.get("iss") not in {"accounts.google.com", "https://accounts.google.com"}:
        raise HTTPException(status_code=401, detail="Émetteur Google invalide.")
    nonce = payload.get("nonce")
    if not isinstance(nonce, str) or not secrets.compare_digest(nonce, expected_nonce):
        raise HTTPException(status_code=401, detail="Nonce Google invalide.")
    if payload.get("email_verified") is not True:
        raise HTTPException(status_code=403, detail="Adresse Google non vérifiée.")
    email = payload.get("email")
    if not isinstance(email, str) or not email:
        raise HTTPException(status_code=401, detail="Adresse Google manquante.")
    return email.lower()
