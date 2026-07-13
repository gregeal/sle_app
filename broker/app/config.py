from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal
from urllib.parse import urlparse

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        enable_decoding=False,
    )

    environment: Literal["development", "test", "production"] = "development"
    public_origin: str = "http://localhost:8000"
    database_path: Path = Path("data/broker.db")
    static_dir: Path | None = None
    trusted_hosts: set[str] = Field(default_factory=lambda: {"*.onrender.com"})

    allowed_emails: set[str] = Field(default_factory=set)
    session_cookie: str = "sle_prep_session"
    session_hours: int = Field(default=12, ge=1, le=24 * 30)

    # Stable secret used to derive privacy-preserving, per-user identifiers.
    # Production must override this value with at least 32 random characters.
    identifier_secret: str = "development-only-identifier-secret"

    google_client_id: str = ""
    google_client_secret: str = ""
    dev_login_enabled: bool = False

    openai_api_key: str = ""
    openai_base_url: str = "https://api.openai.com/v1"
    chat_model: str = "gpt-5-mini"
    allowed_chat_models: set[str] = Field(default_factory=lambda: {"gpt-5-mini"})
    realtime_model: str = "gpt-realtime"
    allowed_realtime_models: set[str] = Field(default_factory=lambda: {"gpt-realtime"})
    allowed_realtime_voices: set[str] = Field(
        default_factory=lambda: {
            "marin",
            "cedar",
            "coral",
            "sage",
            "verse",
            "alloy",
            "ash",
            "ballad",
            "echo",
            "shimmer",
        }
    )

    requests_per_minute: int = Field(default=20, ge=1, le=1_000)
    auth_requests_per_minute: int = Field(default=10, ge=1, le=1_000)
    rate_limit_max_identities: int = Field(default=5_000, ge=100, le=100_000)
    max_request_body_bytes: int = Field(default=262_144, ge=16_384, le=2_097_152)
    daily_budget_usd: float = Field(default=2.0, gt=0, le=10_000)
    monthly_budget_usd: float = Field(default=20.0, gt=0, le=100_000)
    chat_input_usd_per_million: float = Field(default=5.0, gt=0, le=10_000)
    chat_output_usd_per_million: float = Field(default=20.0, gt=0, le=10_000)
    realtime_session_reserve_usd: float = Field(default=1.0, gt=0, le=10_000)
    max_chat_output_tokens: int = Field(default=4_000, ge=16, le=4_096)
    openai_max_retries: int = Field(default=2, ge=0, le=4)
    openai_retry_base_seconds: float = Field(default=0.25, ge=0, le=5)

    cleanup_interval_minutes: int = Field(default=15, ge=1, le=24 * 60)
    reservation_stale_minutes: int = Field(default=60, ge=5, le=24 * 60)
    audit_retention_days: int = Field(default=90, ge=7, le=3_650)
    usage_retention_days: int = Field(default=400, ge=32, le=3_650)

    @field_validator(
        "allowed_emails",
        "allowed_chat_models",
        "allowed_realtime_models",
        "allowed_realtime_voices",
        "trusted_hosts",
        mode="before",
    )
    @classmethod
    def split_csv(cls, value: object) -> object:
        if isinstance(value, str):
            return {part.strip().lower() for part in value.split(",") if part.strip()}
        if isinstance(value, list | set | tuple):
            return {str(part).strip().lower() for part in value if str(part).strip()}
        return value

    @field_validator("environment", mode="before")
    @classmethod
    def normalize_environment(cls, value: object) -> object:
        return value.strip().lower() if isinstance(value, str) else value

    @field_validator("public_origin", "openai_base_url")
    @classmethod
    def strip_trailing_slash(cls, value: str) -> str:
        return value.strip().rstrip("/")

    @model_validator(mode="after")
    def validate_consistency(self) -> Settings:
        origin = urlparse(self.public_origin)
        try:
            origin_port = origin.port
        except ValueError as error:
            raise ValueError("PUBLIC_ORIGIN contains an invalid port") from error
        if (
            origin.scheme not in {"http", "https"}
            or not origin.hostname
            or origin.username
            or origin.password
            or origin.path not in {"", "/"}
            or origin.params
            or origin.query
            or origin.fragment
            or (origin_port is not None and not 1 <= origin_port <= 65_535)
        ):
            raise ValueError(
                "PUBLIC_ORIGIN must be an absolute http(s) origin without a path, "
                "query, or fragment"
            )
        if self.environment == "production" and origin.scheme != "https":
            raise ValueError("PUBLIC_ORIGIN must use HTTPS in production")
        upstream = urlparse(self.openai_base_url)
        try:
            upstream_port = upstream.port
        except ValueError as error:
            raise ValueError("OPENAI_BASE_URL contains an invalid port") from error
        if (
            upstream.scheme not in {"http", "https"}
            or not upstream.hostname
            or upstream.username
            or upstream.password
            or upstream.params
            or upstream.query
            or upstream.fragment
        ):
            raise ValueError(
                "OPENAI_BASE_URL must be an absolute http(s) URL without credentials, "
                "parameters, a query, or a fragment"
            )
        if self.environment == "production" and not (
            upstream.scheme == "https"
            and upstream.hostname == "api.openai.com"
            and upstream_port in {None, 443}
            and upstream.path == "/v1"
        ):
            raise ValueError(
                "OPENAI_BASE_URL must be the official https://api.openai.com/v1 "
                "endpoint in production"
            )
        if bool(self.google_client_id) != bool(self.google_client_secret):
            raise ValueError(
                "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET must be configured together"
            )
        if self.monthly_budget_usd < self.daily_budget_usd:
            raise ValueError("MONTHLY_BUDGET_USD must be at least DAILY_BUDGET_USD")
        if not self.allowed_chat_models:
            raise ValueError("ALLOWED_CHAT_MODELS must not be empty")
        if not self.allowed_realtime_models:
            raise ValueError("ALLOWED_REALTIME_MODELS must not be empty")
        if not self.allowed_realtime_voices:
            raise ValueError("ALLOWED_REALTIME_VOICES must not be empty")
        return self

    @property
    def secure_cookies(self) -> bool:
        return urlparse(self.public_origin).scheme == "https"

    @property
    def official_openai_endpoint(self) -> bool:
        parsed = urlparse(self.openai_base_url)
        try:
            port = parsed.port
        except ValueError:
            return False
        return (
            parsed.scheme == "https"
            and parsed.hostname == "api.openai.com"
            and port in {None, 443}
            and parsed.path == "/v1"
            and not any(
                [
                    parsed.username,
                    parsed.password,
                    parsed.params,
                    parsed.query,
                    parsed.fragment,
                ]
            )
        )

    @property
    def google_enabled(self) -> bool:
        return bool(self.google_client_id and self.google_client_secret)


@lru_cache
def get_settings() -> Settings:
    return Settings()
