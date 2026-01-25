from __future__ import annotations

from openai import OpenAI

from app.core.config import get_settings


def get_openai_client() -> OpenAI:
    settings = get_settings()
    if settings.openai_api_key is None:
        raise RuntimeError("OPENAI_API_KEY is not set. Create backend/.env and set OPENAI_API_KEY.")

    return OpenAI(api_key=settings.openai_api_key.get_secret_value())
