from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.core.config import get_settings
from app.core.openai_client import get_openai_client
from app.schemas import ChatRequest, ChatResponse

router = APIRouter(prefix="/api", tags=["chat"])


@router.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    settings = get_settings()
    client = get_openai_client()

    input_messages = [m.model_dump() for m in req.messages]
    has_instruction = any(m["role"] in {"system", "developer"} for m in input_messages)
    if not has_instruction:
        input_messages = [
            {"role": "system", "content": (req.system_prompt or settings.assistant_system_prompt)},
            *input_messages,
        ]

    try:
        response = client.responses.create(
            model=req.model or settings.openai_model,
            input=input_messages,
            temperature=req.temperature,
        )
        return ChatResponse(reply=response.output_text)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail=f"OpenAI request failed: {exc}")
