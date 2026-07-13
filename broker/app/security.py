from __future__ import annotations

import base64
import hashlib
import hmac
import secrets
import threading
import time
from collections import OrderedDict, deque
from urllib.parse import urlparse

from fastapi import HTTPException, Request, status

from .config import Settings
from .store import BrokerStore, Session


def allowed_email(settings: Settings, email: str) -> bool:
    return email.lower() in settings.allowed_emails


def pseudonymous_user_id(settings: Settings, email: str) -> str:
    """Stable per-user identifier that never exposes the email to clients/providers."""

    digest = hmac.new(
        settings.identifier_secret.encode("utf-8"),
        email.strip().lower().encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return f"sle_{digest}"


def require_session(request: Request) -> Session:
    settings: Settings = request.app.state.settings
    store: BrokerStore = request.app.state.store
    session = store.get_session(request.cookies.get(settings.session_cookie))
    if session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Ouvrez une session pour utiliser les fonctions IA.",
        )
    if not allowed_email(settings, session.email):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Compte non autorisé.")
    return session


def require_csrf(request: Request) -> Session:
    session = require_session(request)
    supplied = request.headers.get("x-csrf-token", "")
    if not supplied or not secrets.compare_digest(supplied, session.csrf_token):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Jeton CSRF invalide.")
    return session


def set_session_cookie(response, settings: Settings, raw_token: str) -> None:
    response.set_cookie(
        settings.session_cookie,
        raw_token,
        max_age=settings.session_hours * 3600,
        httponly=True,
        secure=settings.secure_cookies,
        samesite="strict",
        path="/",
    )


def delete_session_cookie(response, settings: Settings) -> None:
    response.delete_cookie(
        settings.session_cookie,
        httponly=True,
        secure=settings.secure_cookies,
        samesite="strict",
        path="/",
    )


def oauth_pkce() -> tuple[str, str]:
    verifier = secrets.token_urlsafe(64)
    digest = hashlib.sha256(verifier.encode()).digest()
    challenge = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
    return verifier, challenge


def relying_party_id(settings: Settings) -> str:
    host = urlparse(settings.public_origin).hostname
    if not host:
        raise RuntimeError("PUBLIC_ORIGIN must include a hostname")
    return host


class MinuteRateLimiter:
    """Bounded in-process sliding-window limiter for the single-worker broker."""

    def __init__(
        self,
        requests_per_minute: int,
        *,
        max_identities: int = 5_000,
        detail: str = "Trop de demandes IA. Attendez une minute puis réessayez.",
    ):
        self.limit = requests_per_minute
        self.max_identities = max_identities
        self.detail = detail
        self._events: OrderedDict[str, deque[float]] = OrderedDict()
        self._lock = threading.Lock()

    def check(self, identity: str) -> None:
        now = time.monotonic()
        cutoff = now - 60
        with self._lock:
            events = self._events.get(identity)
            if events is None:
                while len(self._events) >= self.max_identities:
                    self._events.popitem(last=False)
                events = deque()
                self._events[identity] = events
            else:
                self._events.move_to_end(identity)
            while events and events[0] <= cutoff:
                events.popleft()
            if len(events) >= self.limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=self.detail,
                )
            events.append(now)

    @property
    def identity_count(self) -> int:
        with self._lock:
            return len(self._events)
