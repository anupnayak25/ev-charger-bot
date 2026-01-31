from __future__ import annotations

from typing import Any

import pytest


def test_voice_ask_happy_path_transcribes_and_replies(client, monkeypatch, dummy_audio_bytes: bytes):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    chat_spy: dict[str, Any] = {}
    stt_spy: dict[str, Any] = {}

    def _fake_get_openai_client():
        return FakeOpenAI(
            transcript="My EV charging session stopped with error E12",
            reply="Check the connector latch and restart the session.",
            chat_spy=chat_spy,
            stt_spy=stt_spy,
        )

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    files = {
        "audio": ("voice.m4a", dummy_audio_bytes, "audio/mp4"),
    }

    res = client.post("/api/voice/ask", files=files)
    assert res.status_code == 200
    body = res.json()
    assert body["transcript"] == "My EV charging session stopped with error E12"
    assert body["reply"] == "Check the connector latch and restart the session."

    assert stt_spy.get("called") is True
    assert chat_spy.get("called") is True

    msgs = chat_spy["kwargs"]["messages"]
    assert msgs[0]["role"] == "system"
    assert msgs[1]["role"] == "user"


def test_voice_rejects_unsupported_extension(client):
    files = {
        "audio": ("voice.ogg", b"not-audio", "application/octet-stream"),
    }

    res = client.post("/api/voice/ask", files=files)
    assert res.status_code == 400
    assert "unsupported" in res.json()["detail"].lower()


def test_voice_offtopic_still_calls_chat_completion_and_sends_scope_prompt(client, monkeypatch, dummy_audio_bytes: bytes):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    chat_spy: dict[str, Any] = {}
    stt_spy: dict[str, Any] = {}

    def _fake_get_openai_client():
        return FakeOpenAI(
            transcript="Tell me a joke about cats",
            reply="(refusal handled by system prompt)",
            chat_spy=chat_spy,
            stt_spy=stt_spy,
        )

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    files = {
        "audio": ("voice.m4a", dummy_audio_bytes, "audio/mp4"),
    }

    res = client.post("/api/voice/ask", files=files)
    assert res.status_code == 200
    assert res.json()["reply"] == "(refusal handled by system prompt)"
    assert stt_spy.get("called") is True
    assert chat_spy.get("called") is True

    msgs = chat_spy["kwargs"]["messages"]
    assert msgs[0]["role"] == "system"
    system_text = (msgs[0]["content"] or "").lower()
    assert "ev charging support" in system_text


@pytest.mark.parametrize(
    "summary",
    [None, "User at a DC fast charger, error E12."],
)
def test_voice_accepts_optional_summary_field(client, monkeypatch, dummy_audio_bytes: bytes, summary: str | None):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    def _fake_get_openai_client():
        return FakeOpenAI(transcript="Charging stops after 10 seconds", reply="Try a different stall")

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    files = {"audio": ("voice.m4a", dummy_audio_bytes, "audio/mp4")}
    data = {}
    if summary is not None:
        data["summary"] = summary

    res = client.post("/api/voice/ask", files=files, data=data)
    assert res.status_code == 200
    assert res.json()["reply"]
