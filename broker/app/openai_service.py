from __future__ import annotations

import json
import math
from dataclasses import dataclass

import httpx
from fastapi import HTTPException, status

from .config import Settings
from .schemas import ChatRequest, RealtimeSessionRequest

REALTIME_INSTRUCTIONS = (
    "Tu es une évaluatrice expérimentée de l'Évaluation de langue seconde "
    "orale du gouvernement du Canada. Conduis une entrevue entièrement en "
    "français, professionnelle, encourageante mais rigoureuse. Commence par "
    "des questions concrètes de niveau A sur le travail, puis passe aux "
    "explications et opinions de niveau B, et enfin aux hypothèses nuancées "
    "de niveau C. Pose une seule question à la fois, fais des relances "
    "naturelles, demande des précisions lorsque la réponse est courte et "
    "n'explique jamais que tu suis un script. Ne donne pas de note pendant "
    "l'entrevue."
)


@dataclass(frozen=True)
class ChatResult:
    text: str
    input_tokens: int
    output_tokens: int


class OpenAiService:
    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None):
        self.settings = settings
        self._client = client or httpx.AsyncClient(timeout=httpx.Timeout(45.0))
        self._owns_client = client is None

    async def close(self) -> None:
        if self._owns_client:
            await self._client.aclose()

    def _headers(self) -> dict[str, str]:
        if not self.settings.openai_api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Le serveur IA n'est pas encore configuré.",
            )
        return {
            "Authorization": f"Bearer {self.settings.openai_api_key}",
            "Content-Type": "application/json",
        }

    async def chat(self, request: ChatRequest) -> ChatResult:
        max_tokens = min(
            request.max_tokens or 1200,
            self.settings.max_chat_output_tokens,
        )
        payload = {
            "model": self.settings.chat_model,
            "messages": [
                {"role": "system", "content": request.system},
                {"role": "user", "content": request.user},
            ],
            "temperature": request.temperature,
            "max_completion_tokens": max_tokens,
        }
        response = await self._post("chat/completions", payload)
        # Some provider/model combinations lock temperature. Retry once without
        # it only when the upstream explicitly identifies that parameter.
        if response.status_code == 400 and "temperature" in response.text.lower():
            payload.pop("temperature")
            response = await self._post("chat/completions", payload)
        self._raise_upstream(response)
        try:
            body = response.json()
            text = body["choices"][0]["message"]["content"]
            usage = body.get("usage") or {}
            if not isinstance(text, str) or not text.strip():
                raise ValueError("empty content")
            return ChatResult(
                text=text.strip(),
                input_tokens=int(usage.get("prompt_tokens") or 0),
                output_tokens=int(usage.get("completion_tokens") or 0),
            )
        except (KeyError, IndexError, TypeError, ValueError, json.JSONDecodeError) as error:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Le fournisseur IA a retourné une réponse invalide.",
            ) from error

    async def realtime_secret(self, request: RealtimeSessionRequest) -> str:
        model = (request.model or self.settings.realtime_model).lower()
        voice = request.voice.lower()
        if model not in self.settings.allowed_realtime_models:
            raise HTTPException(status_code=400, detail="Modèle Realtime non autorisé.")
        if voice not in self.settings.allowed_realtime_voices:
            raise HTTPException(status_code=400, detail="Voix Realtime non autorisée.")
        payload = {
            "session": {
                "type": "realtime",
                "model": model,
                "output_modalities": ["audio"],
                "instructions": REALTIME_INSTRUCTIONS,
                "audio": {
                    "input": {
                        "noise_reduction": {"type": "near_field"},
                        "transcription": {
                            "model": "gpt-4o-mini-transcribe",
                            "language": "fr",
                        },
                        "turn_detection": {
                            "type": "semantic_vad",
                            "eagerness": "medium",
                            "create_response": True,
                            "interrupt_response": True,
                        },
                    },
                    "output": {"voice": voice},
                },
                "max_output_tokens": 800,
            }
        }
        response = await self._post("realtime/client_secrets", payload)
        self._raise_upstream(response)
        try:
            value = response.json()["value"]
            if not isinstance(value, str) or not value:
                raise ValueError("empty token")
            return value
        except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="OpenAI n'a pas retourné de jeton Realtime valide.",
            ) from error

    async def _post(self, suffix: str, payload: dict) -> httpx.Response:
        try:
            return await self._client.post(
                f"{self.settings.openai_base_url}/{suffix}",
                headers=self._headers(),
                json=payload,
            )
        except httpx.TimeoutException as error:
            raise HTTPException(
                status_code=504,
                detail="Le fournisseur IA n'a pas répondu à temps.",
            ) from error
        except httpx.HTTPError as error:
            raise HTTPException(
                status_code=502,
                detail="Connexion impossible au fournisseur IA.",
            ) from error

    @staticmethod
    def _raise_upstream(response: httpx.Response) -> None:
        if 200 <= response.status_code < 300:
            return
        code = response.status_code if response.status_code in {400, 401, 403, 404, 429} else 502
        message = "Le fournisseur IA a refusé la demande."
        try:
            candidate = response.json().get("error", {}).get("message")
            if isinstance(candidate, str) and candidate:
                message = candidate[:500]
        except (ValueError, AttributeError):
            pass
        raise HTTPException(status_code=code, detail=message)


def estimated_chat_cost_micros(request: ChatRequest, settings: Settings) -> int:
    # A BPE token cannot contain less than one source byte. Reserving one token
    # per UTF-8 byte is deliberately conservative and keeps the preflight
    # reservation from underestimating multilingual prompts.
    estimated_input_tokens = max(1, len((request.system + request.user).encode("utf-8")))
    output_tokens = min(request.max_tokens or 1200, settings.max_chat_output_tokens)
    usd = (
        estimated_input_tokens * settings.chat_input_usd_per_million
        + output_tokens * settings.chat_output_usd_per_million
    ) / 1_000_000
    return max(1, math.ceil(usd * 1_000_000))


def actual_chat_cost_micros(result: ChatResult, settings: Settings) -> int:
    usd = (
        result.input_tokens * settings.chat_input_usd_per_million
        + result.output_tokens * settings.chat_output_usd_per_million
    ) / 1_000_000
    return max(1, math.ceil(usd * 1_000_000))
