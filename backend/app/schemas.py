from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class ChatTurn(BaseModel):
    user: str = Field(min_length=1)
    assistant: Optional[str] = None


class ChatRequest(BaseModel):
    turns: list[ChatTurn] = Field(min_length=1)
    system_prompt: Optional[str] = None
    summary: Optional[str] = Field(
        default=None,
        description="Short running summary of the conversation so far (client-maintained).",
    )


class ChatResponse(BaseModel):
    reply: str


class VoiceResponse(BaseModel):
    transcript: str
    reply: str
