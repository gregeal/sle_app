from __future__ import annotations

import hashlib
import json
import secrets
import sqlite3
import threading
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from pathlib import Path


def _now() -> datetime:
    return datetime.now(UTC)


def _iso(value: datetime) -> str:
    return value.astimezone(UTC).isoformat()


def _hash(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


@dataclass(frozen=True)
class Session:
    email: str
    csrf_token: str
    expires_at: datetime


@dataclass(frozen=True)
class PasskeyCredential:
    credential_id: bytes
    public_key: bytes
    sign_count: int
    transports: list[str]


class BrokerStore:
    """Small SQLite store. No prompt, transcript, token, or provider secret is persisted."""

    def __init__(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        self._connection = sqlite3.connect(path, check_same_thread=False)
        self._connection.row_factory = sqlite3.Row
        self._lock = threading.RLock()
        with self._lock:
            self._connection.executescript(
                """
                PRAGMA journal_mode=WAL;
                PRAGMA foreign_keys=ON;
                CREATE TABLE IF NOT EXISTS sessions (
                  token_hash TEXT PRIMARY KEY,
                  email TEXT NOT NULL,
                  csrf_token TEXT NOT NULL,
                  expires_at TEXT NOT NULL,
                  created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS auth_challenges (
                  id TEXT PRIMARY KEY,
                  kind TEXT NOT NULL,
                  email TEXT,
                  challenge BLOB,
                  verifier TEXT,
                  expires_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS passkeys (
                  credential_id BLOB PRIMARY KEY,
                  email TEXT NOT NULL,
                  public_key BLOB NOT NULL,
                  sign_count INTEGER NOT NULL,
                  transports TEXT NOT NULL DEFAULT '[]',
                  created_at TEXT NOT NULL,
                  last_used_at TEXT
                );
                CREATE INDEX IF NOT EXISTS passkeys_email_idx ON passkeys(email);
                CREATE TABLE IF NOT EXISTS usage_reservations (
                  request_id TEXT PRIMARY KEY,
                  email TEXT NOT NULL,
                  route TEXT NOT NULL,
                  cost_micros INTEGER NOT NULL,
                  created_at TEXT NOT NULL,
                  status TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS usage_email_time_idx
                  ON usage_reservations(email, created_at);
                CREATE TABLE IF NOT EXISTS audit_events (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  email TEXT NOT NULL,
                  route TEXT NOT NULL,
                  outcome TEXT NOT NULL,
                  status_code INTEGER NOT NULL,
                  created_at TEXT NOT NULL
                );
                """
            )
            self._connection.commit()

    def close(self) -> None:
        with self._lock:
            self._connection.close()

    def create_session(self, email: str, hours: int) -> tuple[str, Session]:
        raw_token = secrets.token_urlsafe(32)
        session = Session(
            email=email.lower(),
            csrf_token=secrets.token_urlsafe(24),
            expires_at=_now() + timedelta(hours=hours),
        )
        with self._lock:
            self._connection.execute(
                "INSERT INTO sessions VALUES (?, ?, ?, ?, ?)",
                (
                    _hash(raw_token),
                    session.email,
                    session.csrf_token,
                    _iso(session.expires_at),
                    _iso(_now()),
                ),
            )
            self._connection.commit()
        return raw_token, session

    def get_session(self, raw_token: str | None) -> Session | None:
        if not raw_token:
            return None
        with self._lock:
            row = self._connection.execute(
                "SELECT email, csrf_token, expires_at FROM sessions WHERE token_hash = ?",
                (_hash(raw_token),),
            ).fetchone()
            if row is None:
                return None
            expires_at = datetime.fromisoformat(row["expires_at"])
            if expires_at <= _now():
                self._connection.execute(
                    "DELETE FROM sessions WHERE token_hash = ?", (_hash(raw_token),)
                )
                self._connection.commit()
                return None
            return Session(row["email"], row["csrf_token"], expires_at)

    def delete_session(self, raw_token: str | None) -> None:
        if not raw_token:
            return
        with self._lock:
            self._connection.execute(
                "DELETE FROM sessions WHERE token_hash = ?",
                (_hash(raw_token),),
            )
            self._connection.commit()

    def put_challenge(
        self,
        *,
        kind: str,
        email: str | None = None,
        challenge: bytes | None = None,
        verifier: str | None = None,
        ttl_minutes: int = 5,
    ) -> str:
        challenge_id = secrets.token_urlsafe(24)
        with self._lock:
            self._connection.execute(
                "INSERT INTO auth_challenges VALUES (?, ?, ?, ?, ?, ?)",
                (
                    challenge_id,
                    kind,
                    email.lower() if email else None,
                    challenge,
                    verifier,
                    _iso(_now() + timedelta(minutes=ttl_minutes)),
                ),
            )
            self._connection.commit()
        return challenge_id

    def consume_challenge(self, challenge_id: str, kind: str) -> sqlite3.Row | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT * FROM auth_challenges WHERE id = ? AND kind = ?",
                (challenge_id, kind),
            ).fetchone()
            self._connection.execute("DELETE FROM auth_challenges WHERE id = ?", (challenge_id,))
            self._connection.commit()
        if row is None or datetime.fromisoformat(row["expires_at"]) <= _now():
            return None
        return row

    def passkeys_for_email(self, email: str) -> list[PasskeyCredential]:
        with self._lock:
            rows = self._connection.execute(
                "SELECT * FROM passkeys WHERE email = ? ORDER BY created_at", (email.lower(),)
            ).fetchall()
        return [
            PasskeyCredential(
                credential_id=bytes(row["credential_id"]),
                public_key=bytes(row["public_key"]),
                sign_count=row["sign_count"],
                transports=json.loads(row["transports"]),
            )
            for row in rows
        ]

    def passkey_by_id(self, credential_id: bytes) -> tuple[str, PasskeyCredential] | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT * FROM passkeys WHERE credential_id = ?", (credential_id,)
            ).fetchone()
        if row is None:
            return None
        return row["email"], PasskeyCredential(
            credential_id=bytes(row["credential_id"]),
            public_key=bytes(row["public_key"]),
            sign_count=row["sign_count"],
            transports=json.loads(row["transports"]),
        )

    def save_passkey(self, email: str, credential: PasskeyCredential) -> None:
        with self._lock:
            self._connection.execute(
                "INSERT INTO passkeys VALUES (?, ?, ?, ?, ?, ?, NULL)",
                (
                    credential.credential_id,
                    email.lower(),
                    credential.public_key,
                    credential.sign_count,
                    json.dumps(credential.transports),
                    _iso(_now()),
                ),
            )
            self._connection.commit()

    def update_passkey_count(self, credential_id: bytes, sign_count: int) -> None:
        with self._lock:
            self._connection.execute(
                "UPDATE passkeys SET sign_count = ?, last_used_at = ? WHERE credential_id = ?",
                (sign_count, _iso(_now()), credential_id),
            )
            self._connection.commit()

    def reserve_usage(
        self,
        *,
        email: str,
        route: str,
        cost_micros: int,
        daily_limit_micros: int,
        monthly_limit_micros: int,
    ) -> str | None:
        now = _now()
        day_start = datetime(now.year, now.month, now.day, tzinfo=UTC)
        month_start = datetime(now.year, now.month, 1, tzinfo=UTC)
        request_id = secrets.token_urlsafe(18)
        with self._lock:
            self._connection.execute("BEGIN IMMEDIATE")
            try:
                day_total = self._connection.execute(
                    "SELECT COALESCE(SUM(cost_micros), 0) FROM usage_reservations "
                    "WHERE email = ? AND created_at >= ? AND status != 'released'",
                    (email, _iso(day_start)),
                ).fetchone()[0]
                month_total = self._connection.execute(
                    "SELECT COALESCE(SUM(cost_micros), 0) FROM usage_reservations "
                    "WHERE email = ? AND created_at >= ? AND status != 'released'",
                    (email, _iso(month_start)),
                ).fetchone()[0]
                if day_total + cost_micros > daily_limit_micros or (
                    month_total + cost_micros > monthly_limit_micros
                ):
                    self._connection.rollback()
                    return None
                self._connection.execute(
                    "INSERT INTO usage_reservations VALUES (?, ?, ?, ?, ?, 'reserved')",
                    (request_id, email, route, cost_micros, _iso(now)),
                )
                self._connection.commit()
                return request_id
            except Exception:
                self._connection.rollback()
                raise

    def settle_usage(self, request_id: str, cost_micros: int, *, released: bool = False) -> None:
        with self._lock:
            self._connection.execute(
                "UPDATE usage_reservations SET cost_micros = ?, status = ? WHERE request_id = ?",
                (cost_micros, "released" if released else "settled", request_id),
            )
            self._connection.commit()

    def audit(self, email: str, route: str, outcome: str, status_code: int) -> None:
        with self._lock:
            self._connection.execute(
                "INSERT INTO audit_events(email, route, outcome, status_code, created_at) "
                "VALUES (?, ?, ?, ?, ?)",
                (email, route, outcome, status_code, _iso(_now())),
            )
            self._connection.commit()
