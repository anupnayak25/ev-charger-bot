from __future__ import annotations

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import StreamingResponse

from app.core.config import get_settings
from app.core.openai_client import get_openai_client
from app.schemas import SpeakRequest

router = APIRouter(prefix="/api/voice", tags=["voice"])


@router.post("/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    settings = get_settings()
    client = get_openai_client()

    try:
        result = client.audio.transcriptions.create(
            model=settings.openai_stt_model,
            file=audio.file,
        )
        return {"text": result.text}
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail=f"OpenAI STT failed: {exc}")


@router.post("/speak")
def speak(req: SpeakRequest):
    settings = get_settings()
    client = get_openai_client()

    media_type = "audio/mpeg" if req.format == "mp3" else "audio/wav"

    def generate():
        try:
            with client.audio.speech.with_streaming_response.create(
                model=settings.openai_tts_model,
                voice=req.voice,
                input=req.text,
                format=req.format,
            ) as response:
                for chunk in response.iter_bytes():
                    yield chunk
        except Exception as exc:  # pragma: no cover
            # StreamingResponse can't easily raise HTTPException mid-stream.
            raise RuntimeError(f"OpenAI TTS failed: {exc}")

    return StreamingResponse(generate(), media_type=media_type)
