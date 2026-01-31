from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEFAULT_ASSISTANT_SYSTEM_PROMPT = (
    "You are an EV CHARGING SUPPORT assistant. Your ONLY scope is electric-vehicle charging: "
    "EV chargers/stations, connectors (CCS, Type 2, J1772, CHAdeMO), charging sessions, "
    "apps/RFID payments, error codes, power (kW), battery/SOC as it relates to charging, "
    "cables, AC/DC charging, home wallboxes, public charging networks, and safe troubleshooting.\n\n"
    "Important: Do NOT refuse just because the user is brief or ambiguous. If a message could plausibly "
    "be about EV charging, treat it as in-scope and ask 1–3 clarifying questions. Examples that are "
    "in-scope even without explicit 'EV' wording: 'the screen is blank', 'charging is slow', "
    "'charging is complete but I cannot disconnect the cable'.\n\n"
    "Only refuse when the user is clearly asking about something unrelated to EV charging (e.g., general "
    "coding, math homework, health, relationships, news, entertainment). "
    "When refusing, redirect back to EV charging. Use this refusal style:\n"
    "- One short sentence refusing due to scope.\n"
    "- One short sentence asking an EV-charging related question or offering EV-charging help.\n\n"
    "When in scope, ask concise clarifying questions when needed (charger model/network, connector type, "
    "vehicle, error code/message, app/RFID status, session state, AC vs DC, location). Provide "
    "step-by-step troubleshooting and safe checks. Do not claim to perform actions you cannot do."
)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "ev-charger-bot-backend"
    environment: str = "dev"

    # OpenAI
    openai_api_key: SecretStr | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str = Field("gpt-4o-mini", alias="OPENAI_MODEL")
    openai_temperature: float = Field(0.2, alias="OPENAI_TEMPERATURE")

    # Assistant behavior (persona)
    assistant_system_prompt: str = Field(
        default=DEFAULT_ASSISTANT_SYSTEM_PROMPT,
        alias="EV_ASSISTANT_SYSTEM_PROMPT",
    )

    @field_validator("assistant_system_prompt")
    @classmethod
    def _fallback_if_blank(cls, value: str) -> str:
        # If the env var exists but is empty/whitespace, keep a safe built-in default.
        if not str(value).strip():
            return DEFAULT_ASSISTANT_SYSTEM_PROMPT
        return value

    # Audio
    openai_stt_model: str = Field("gpt-4o-mini-transcribe", alias="OPENAI_STT_MODEL")
    openai_tts_model: str = Field("gpt-4o-mini-tts", alias="OPENAI_TTS_MODEL")

    # CORS
    cors_origins: List[str] = Field(default_factory=lambda: ["*"])


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
