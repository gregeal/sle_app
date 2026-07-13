from typing import Any

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    system: str = Field(min_length=1, max_length=50_000)
    user: str = Field(min_length=1, max_length=50_000)
    temperature: float = Field(default=0.7, ge=0, le=2)
    max_tokens: int | None = Field(default=None, ge=1, le=4_096)


class RealtimeSessionRequest(BaseModel):
    model: str | None = Field(default=None, min_length=1, max_length=100)
    voice: str = Field(default="marin", min_length=1, max_length=40)


class PasskeyFinishRequest(BaseModel):
    challenge_id: str = Field(min_length=10, max_length=200)
    credential: dict[str, Any]


class PasskeyLoginOptionsRequest(BaseModel):
    email: str = Field(min_length=3, max_length=320)
