from __future__ import annotations

import json
import secrets
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
from starlette.middleware.trustedhost import TrustedHostMiddleware

from .config import Settings, get_settings
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
    require_csrf,
    set_session_cookie,
)
from .store import BrokerStore, Session

CsrfSession = Annotated[Session, Depends(require_csrf)]


def create_app(
    settings: Settings | None = None,
    *,
    openai_client: httpx.AsyncClient | None = None,
) -> FastAPI:
    settings = settings or get_settings()
    if settings.environment == "production" and not settings.allowed_emails:
        raise RuntimeError("ALLOWED_EMAILS must not be empty in production")

    store = BrokerStore(settings.database_path)
    openai = OpenAiService(settings, openai_client)
    rate_limiter = MinuteRateLimiter(settings.requests_per_minute)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
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

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
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
        if request.url.path.startswith("/api/"):
            response.headers["Cache-Control"] = "no-store"
        return response

    @app.get("/api/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/api/auth/session")
    async def auth_session(request: Request) -> dict:
        session = store.get_session(request.cookies.get(settings.session_cookie))
        if session is None or not allowed_email(settings, session.email):
            return {
                "authenticated": False,
                "googleEnabled": settings.google_enabled,
                "passkeysEnabled": True,
            }
        return {
            "authenticated": True,
            "email": session.email,
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
    async def google_start() -> Response:
        if not settings.google_enabled:
            raise HTTPException(status_code=503, detail="Google OAuth n'est pas configuré.")
        verifier, code_challenge = oauth_pkce()
        state_value = store.put_challenge(kind="google-oauth", verifier=verifier)
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
        return registration_options(store, settings, session.email)

    @app.post("/api/auth/passkeys/register/finish")
    async def passkey_register_finish(
        body: PasskeyFinishRequest,
        session: CsrfSession,
    ) -> dict[str, bool]:
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
        rate_limiter.check(f"passkey:{email}:{request.client.host if request.client else ''}")
        if not allowed_email(settings, email):
            # Deliberately match the no-credential response to limit account discovery.
            raise HTTPException(status_code=404, detail="Aucune passkey disponible.")
        try:
            return authentication_options(store, settings, email)
        except LookupError as error:
            raise HTTPException(status_code=404, detail="Aucune passkey disponible.") from error

    @app.post("/api/auth/passkeys/login/finish")
    async def passkey_login_finish(body: PasskeyFinishRequest) -> Response:
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
        reservation = _reserve(store, settings, session.email, "/api/chat", estimated)
        try:
            result = await openai.chat(body)
        except HTTPException as error:
            store.settle_usage(reservation, 0, released=True)
            store.audit(session.email, "/api/chat", "upstream-error", error.status_code)
            raise
        actual_cost = actual_chat_cost_micros(result, settings)
        if result.input_tokens == 0 and result.output_tokens == 0:
            # Do not turn a provider's missing usage metadata into a near-zero
            # charge that can bypass the configured budget ceiling.
            actual_cost = estimated
        store.settle_usage(reservation, actual_cost)
        store.audit(session.email, "/api/chat", "ok", 200)
        return {"text": result.text}

    @app.post("/api/realtime/session")
    async def realtime_session(
        body: RealtimeSessionRequest,
        session: CsrfSession,
    ) -> dict[str, str]:
        rate_limiter.check(session.email)
        reserve_micros = max(1, round(settings.realtime_session_reserve_usd * 1_000_000))
        reservation = _reserve(
            store,
            settings,
            session.email,
            "/api/realtime/session",
            reserve_micros,
        )
        try:
            value = await openai.realtime_secret(body)
        except HTTPException as error:
            store.settle_usage(reservation, 0, released=True)
            store.audit(session.email, "/api/realtime/session", "upstream-error", error.status_code)
            raise
        store.settle_usage(reservation, reserve_micros)
        store.audit(session.email, "/api/realtime/session", "ok", 200)
        return {"value": value}

    static_dir = settings.static_dir
    if static_dir is not None and Path(static_dir).is_dir():
        app.mount("/", StaticFiles(directory=static_dir, html=True), name="web")
    return app


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
    if payload.get("email_verified") is not True:
        raise HTTPException(status_code=403, detail="Adresse Google non vérifiée.")
    email = payload.get("email")
    if not isinstance(email, str) or not email:
        raise HTTPException(status_code=401, detail="Adresse Google manquante.")
    return email.lower()
