from __future__ import annotations

from typing import Any

import pytest


def test_root_healthcheck(client):
    res = client.get("/")
    assert res.status_code == 200
    assert res.json()["message"]


def test_chat_happy_path_calls_openai_and_returns_reply(client, monkeypatch):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    spy: dict[str, Any] = {}

    def _fake_get_openai_client():
        return FakeOpenAI(reply="Try replugging the CCS connector.", chat_spy=spy)

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    payload = {
        "turns": [
            {
                "user": "My EV won't start charging at a CCS station. Any steps?",
            }
        ]
    }

    res = client.post("/api/chat", json=payload)
    assert res.status_code == 200
    assert res.json()["reply"] == "Try replugging the CCS connector."
    assert spy.get("called") is True

    # Ensure we send a system message first.
    msgs = spy["kwargs"]["messages"]
    assert msgs[0]["role"] == "system"


def test_chat_offtopic_still_calls_openai_and_sends_scope_prompt(client, monkeypatch):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    spy: dict[str, Any] = {}

    def _fake_get_openai_client():
        return FakeOpenAI(reply="(refusal handled by system prompt)", chat_spy=spy)

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    payload = {
        "turns": [
            {
                "user": "Write me a poem about the ocean.",
            }
        ]
    }

    res = client.post("/api/chat", json=payload)
    assert res.status_code == 200
    assert spy.get("called") is True

    msgs = spy["kwargs"]["messages"]
    assert msgs[0]["role"] == "system"
    system_text = (msgs[0]["content"] or "").lower()
    assert "ev charging support" in system_text
    assert "only refuse" in system_text


@pytest.mark.parametrize(
    "user",
    [
        "My Type 2 charger keeps stopping.",
        "CCS fast charging is capped at 20kW.",
        "Charging session fails after RFID tap.",
    ],
)
def test_chat_allows_in_scope_ev_charging_topics(client, monkeypatch, user: str):
    from app.core import openai_client
    from tests.conftest import FakeOpenAI

    def _fake_get_openai_client():
        return FakeOpenAI(reply="In-scope response")

    monkeypatch.setattr(openai_client, "get_openai_client", _fake_get_openai_client)

    res = client.post("/api/chat", json={"turns": [{"user": user}]})
    assert res.status_code == 200
    assert res.json()["reply"] == "In-scope response"
