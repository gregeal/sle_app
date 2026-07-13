from __future__ import annotations

import base64
import hashlib
import secrets
import threading
from collections import defaultdict, deque
from datetime import UTC, datetime, timedelta
from urllib.parse import urlparse

from fastapi import HTTPException, Request, status

from .config import Settings
from .store import BrokerStore, Session


def allowed_email(settings: Settings, email: str) -> bool:
    return email.lower() in settings.allowed_emails


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
    def __init__(self, requests_per_minute: int):
        self.limit = requests_per_minute
        self._events: dict[str, deque[datetime]] = defaultdict(deque)
        self._lock = threading.Lock()

    def check(self, identity: str) -> None:
        now = datetime.now(UTC)
        cutoff = now - timedelta(minutes=1)
        with self._lock:
            events = self._events[identity]
            while events and events[0] <= cutoff:
                events.popleft()
            if len(events) >= self.limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Trop de demandes IA. Attendez une minute puis réessayez.",
                )
            events.append(now)
