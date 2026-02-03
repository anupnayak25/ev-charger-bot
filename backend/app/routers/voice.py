from __future__ import annotations

import logging
import os

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.core.config import get_settings
from app.core import openai_client
from app.schemas import VoiceResponse

router = APIRouter(prefix="/api/voice", tags=["voice"])

logger = logging.getLogger(__name__)


@router.post("/ask", response_model=VoiceResponse)
def ask(
    audio: UploadFile = File(...),
    summary: str | None = Form(default=None),
    system_prompt: str | None = Form(default=None),
) -> VoiceResponse:
    """Speech-to-answer: transcribe audio and return the assistant's text reply."""

    settings = get_settings()
    client = openai_client.get_openai_client()

    filename = audio.filename or "audio"
    _, ext = os.path.splitext(filename)
    ext = ext.lower().lstrip(".")
    supported_exts = {"mp3", "mp4", "mpeg", "mpga", "m4a", "wav", "webm"}
    if ext and ext not in supported_exts:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported audio file type '.{ext}'. "
                f"Supported: {', '.join(sorted(supported_exts))}."
            ),
        )

    try:
        try:
            audio.file.seek(0)
        except Exception:
            pass

        stt = client.audio.transcriptions.create(
            model=settings.openai_stt_model,
            file=(filename, audio.file, audio.content_type or "application/octet-stream"),
        )
        transcript = (stt.text or "").strip()
        if not transcript:
            raise HTTPException(status_code=400, detail="Could not transcribe audio (empty transcript).")

        system_content = system_prompt or settings.assistant_system_prompt
        if summary and summary.strip():
            system_content = (
                system_content
                + "\n\nConversation summary (client-maintained). Treat as context and constraints:\n"
                + summary.strip()
            )

        messages: list[dict[str, str]] = [
            {"role": "system", "content": system_content},
            {"role": "user", "content": transcript},
        ]

        response = client.chat.completions.create(
            model=settings.openai_model,
            temperature=settings.openai_temperature,
            messages=messages,
        )
        reply = response.choices[0].message.content or ""
        return VoiceResponse(transcript=transcript, reply=reply)
    except HTTPException:
        raise
    except Exception as exc: 
        logger.exception("Voice ask failed")
        raise HTTPException(
            status_code=500,
            detail="AI provider request failed. See server logs.",
        )
