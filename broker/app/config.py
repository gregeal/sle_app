from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        enable_decoding=False,
    )

    environment: str = "development"
    public_origin: str = "http://localhost:8000"
    database_path: Path = Path("data/broker.db")
    static_dir: Path | None = None
    trusted_hosts: set[str] = Field(default_factory=lambda: {"*.onrender.com"})

    allowed_emails: set[str] = Field(default_factory=set)
    session_cookie: str = "sle_prep_session"
    session_hours: int = 12

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

    requests_per_minute: int = 20
    daily_budget_usd: float = 2.0
    monthly_budget_usd: float = 20.0
    chat_input_usd_per_million: float = 5.0
    chat_output_usd_per_million: float = 20.0
    realtime_session_reserve_usd: float = 1.0
    max_chat_output_tokens: int = 2000

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
        return value

    @field_validator("public_origin", "openai_base_url")
    @classmethod
    def strip_trailing_slash(cls, value: str) -> str:
        return value.rstrip("/")

    @property
    def secure_cookies(self) -> bool:
        return self.public_origin.startswith("https://")

    @property
    def google_enabled(self) -> bool:
        return bool(self.google_client_id and self.google_client_secret)


@lru_cache
def get_settings() -> Settings:
    return Settings()
