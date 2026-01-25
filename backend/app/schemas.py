from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field


ChatRole = Literal["system", "user", "assistant", "developer"]


class ChatMessage(BaseModel):
    role: ChatRole
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(min_length=1)
    system_prompt: Optional[str] = None
    model: Optional[str] = None
    temperature: Optional[float] = Field(default=None, ge=0.0, le=2.0)


class ChatResponse(BaseModel):
    reply: str


class SpeakRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)
    voice: str = "alloy"
    format: Literal["mp3", "wav"] = "mp3"
