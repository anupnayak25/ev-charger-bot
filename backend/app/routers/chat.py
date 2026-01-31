from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.core.config import get_settings
from app.core import openai_client
from app.schemas import ChatRequest, ChatResponse

router = APIRouter(prefix="/api", tags=["chat"])


@router.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    settings = get_settings()
    client = openai_client.get_openai_client()

    system_content = req.system_prompt or settings.assistant_system_prompt
    if req.summary and req.summary.strip():
        system_content = (
            system_content
            + "\n\nConversation summary (client-maintained). Treat as context and constraints:\n"
            + req.summary.strip()
        )

    messages: list[dict[str, str]] = [{"role": "system", "content": system_content}]

    for turn in req.turns:
        messages.append({"role": "user", "content": turn.user})
        if turn.assistant:
            messages.append({"role": "assistant", "content": turn.assistant})

    try:
        response = client.chat.completions.create(
            model=settings.openai_model,
            temperature=settings.openai_temperature,
            messages=messages,
        )
        reply = response.choices[0].message.content or ""
        return ChatResponse(reply=reply)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail=f"OpenAI request failed: {exc}")
