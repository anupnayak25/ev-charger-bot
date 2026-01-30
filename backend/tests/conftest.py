from __future__ import annotations

import io
from dataclasses import dataclass
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import create_app


@dataclass
class _FakeChoiceMessage:
    content: str


@dataclass
class _FakeChoice:
    message: _FakeChoiceMessage


@dataclass
class _FakeChatResponse:
    choices: list[_FakeChoice]


class _FakeTranscription:
    def __init__(self, text: str):
        self.text = text


class _FakeCompletions:
    def __init__(self, reply: str, spy: dict[str, Any] | None = None):
        self._reply = reply
        self._spy = spy

    def create(self, **kwargs: Any) -> _FakeChatResponse:
        if self._spy is not None:
            self._spy["called"] = True
            self._spy["kwargs"] = kwargs
        return _FakeChatResponse(choices=[_FakeChoice(_FakeChoiceMessage(self._reply))])


class _FakeChat:
    def __init__(self, reply: str, spy: dict[str, Any] | None = None):
        self.completions = _FakeCompletions(reply=reply, spy=spy)


class _FakeTranscriptions:
    def __init__(self, transcript: str, spy: dict[str, Any] | None = None):
        self._transcript = transcript
        self._spy = spy

    def create(self, **kwargs: Any) -> _FakeTranscription:
        if self._spy is not None:
            self._spy["called"] = True
            self._spy["kwargs"] = kwargs
        return _FakeTranscription(self._transcript)


class _FakeAudio:
    def __init__(self, transcript: str, spy: dict[str, Any] | None = None):
        self.transcriptions = _FakeTranscriptions(transcript=transcript, spy=spy)


class FakeOpenAI:
    def __init__(
        self,
        *,
        reply: str = "OK",
        transcript: str = "transcript",
        chat_spy: dict[str, Any] | None = None,
        stt_spy: dict[str, Any] | None = None,
    ):
        self.chat = _FakeChat(reply=reply, spy=chat_spy)
        self.audio = _FakeAudio(transcript=transcript, spy=stt_spy)


@pytest.fixture()
def client():
    app = create_app()
    return TestClient(app)


@pytest.fixture()
def dummy_audio_bytes() -> bytes:
    # The backend doesn't validate actual audio contents; it only checks extension.
    return b"RIFF....WAVEfmt "


@pytest.fixture()
def dummy_audio_file(dummy_audio_bytes: bytes):
    return io.BytesIO(dummy_audio_bytes)
