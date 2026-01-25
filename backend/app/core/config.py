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

    # Assistant behavior (persona)
    assistant_system_prompt: str = Field(
        default=(
            "You are an EV charging-station support assistant. Your job is to help users resolve "
            "charging issues and answer questions clearly and safely. Ask concise clarifying questions "
            "when needed (charger model, connector type, vehicle, error code, app/network status, "
            "session state). Provide step-by-step troubleshooting and explain what to check next. "
            "Do not claim to perform actions you cannot do. If a request is unsafe or unrelated, "
            "refuse and offer a safer alternative."
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
