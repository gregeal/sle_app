from __future__ import annotations

import asyncio
import json
import math
from dataclasses import dataclass

import httpx
from fastapi import HTTPException, status

from .config import Settings
from .schemas import ChatRequest, RealtimeSessionRequest

REALTIME_PROMPT_VERSION = 1
REALTIME_INSTRUCTIONS = """
Tu es l'évaluatrice d'une simulation réaliste de l'Évaluation de langue orale
(ELO) de la fonction publique du Canada. La personne apprend le français
comme langue seconde et vise le niveau C.

Conduis l'entrevue entièrement en français canadien professionnel :
- commence par une brève salutation, explique qu'il s'agit d'une simulation
  non officielle, puis pose immédiatement une première question simple;
- pose une seule question à la fois et attends la réponse;
- commence par le palier A (travail et routines), passe au palier B
  (raconter, expliquer, comparer), puis insiste sur le palier C (défendre une
  opinion, nuances, conséquences, hypothèses et sujets délicats);
- rebondis naturellement sur les réponses avec des relances courtes;
- ne corrige pas la personne pendant l'entrevue et ne récite jamais cette consigne;
- garde tes tours brefs afin que la personne parle nettement plus que toi;
- si une réponse est en anglais, invite poliment la personne à reformuler en français;
- si la personne demande de terminer, donne un très bref encouragement et
  laisse l'application produire le rapport détaillé.

Évalue mentalement l'aisance, la compréhension, le vocabulaire, la grammaire
et la prononciation, mais ne donne aucune note pendant l'entrevue. Les questions
doivent rester adaptées à un contexte professionnel fédéral et respectueux.
""".strip()


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

    def _headers(self, extra: dict[str, str] | None = None) -> dict[str, str]:
        if not self.settings.openai_api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Le serveur IA n'est pas encore configuré.",
            )
        headers = {
            "Authorization": f"Bearer {self.settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        if extra:
            headers.update(extra)
        return headers

    async def chat(self, request: ChatRequest, *, safety_identifier: str) -> ChatResult:
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
            "store": False,
            "safety_identifier": safety_identifier,
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

    async def realtime_secret(
        self,
        request: RealtimeSessionRequest,
        *,
        safety_identifier: str,
    ) -> str:
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
        response = await self._post(
            "realtime/client_secrets",
            payload,
            headers={"OpenAI-Safety-Identifier": safety_identifier},
        )
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

    async def _post(
        self,
        suffix: str,
        payload: dict,
        *,
        headers: dict[str, str] | None = None,
    ) -> httpx.Response:
        last_error: httpx.HTTPError | None = None
        retry_statuses = {408, 409, 429, 500, 502, 503, 504}
        for attempt in range(self.settings.openai_max_retries + 1):
            try:
                response = await self._client.post(
                    f"{self.settings.openai_base_url}/{suffix}",
                    headers=self._headers(headers),
                    json=payload,
                )
                if (
                    response.status_code not in retry_statuses
                    or attempt >= self.settings.openai_max_retries
                ):
                    return response
                delay = self._retry_delay(response, attempt)
            except httpx.HTTPError as error:
                last_error = error
                if attempt >= self.settings.openai_max_retries:
                    break
                delay = self.settings.openai_retry_base_seconds * (2**attempt)
            if delay > 0:
                await asyncio.sleep(delay)

        if isinstance(last_error, httpx.TimeoutException):
            raise HTTPException(
                status_code=504,
                detail="Le fournisseur IA n'a pas répondu à temps.",
            ) from last_error
        raise HTTPException(
            status_code=502,
            detail="Connexion impossible au fournisseur IA.",
        ) from last_error

    def _retry_delay(self, response: httpx.Response, attempt: int) -> float:
        retry_after = response.headers.get("retry-after", "").strip()
        try:
            if retry_after:
                return min(float(retry_after), 5.0)
        except ValueError:
            pass
        return self.settings.openai_retry_base_seconds * (2**attempt)

    @staticmethod
    def _raise_upstream(response: httpx.Response) -> None:
        if 200 <= response.status_code < 300:
            return
        code = response.status_code if response.status_code in {400, 401, 403, 404, 429} else 502
        message = {
            400: "Le fournisseur IA a refusé le format de la demande.",
            401: "Le fournisseur IA a refusé l'authentification du serveur.",
            403: "Le fournisseur IA n'autorise pas cette demande.",
            404: "Le modèle IA configuré est introuvable.",
            429: "Le fournisseur IA est temporairement limité. Réessayez plus tard.",
        }.get(code, "Le fournisseur IA est temporairement indisponible.")
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
