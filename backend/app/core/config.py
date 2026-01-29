from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


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
        default=(
            "You are an EV CHARGING SUPPORT assistant. Your ONLY scope is electric-vehicle charging: "
            "EV chargers/stations, connectors (CCS, Type 2, J1772, CHAdeMO), charging sessions, "
            "apps/RFID payments, error codes, power (kW), battery/SOC as it relates to charging, "
            "cables, AC/DC charging, home wallboxes, public charging networks, and safe troubleshooting.\n\n"
            "If the user asks about ANYTHING outside EV charging (e.g., general coding, math, health, "
            "relationships, news, entertainment, general vehicle maintenance unrelated to charging), "
            "you MUST refuse and redirect. Use this refusal style:\n"
            "- One short sentence refusing due to scope.\n"
            "- One short sentence asking an EV-charging related question or offering EV-charging help.\n\n"
            "When in scope, ask concise clarifying questions when needed (charger model/network, connector type, "
            "vehicle, error code/message, app/RFID status, session state, AC vs DC, location). Provide "
            "step-by-step troubleshooting and safe checks. Do not claim to perform actions you cannot do."
        ),
        alias="EV_ASSISTANT_SYSTEM_PROMPT",
    )

    # Audio
    openai_stt_model: str = Field("gpt-4o-mini-transcribe", alias="OPENAI_STT_MODEL")
    openai_tts_model: str = Field("gpt-4o-mini-tts", alias="OPENAI_TTS_MODEL")

    # CORS
    cors_origins: List[str] = Field(default_factory=lambda: ["*"])


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
