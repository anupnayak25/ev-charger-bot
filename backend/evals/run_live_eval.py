from __future__ import annotations

import json
import os
import importlib
from dataclasses import dataclass
from pathlib import Path


@dataclass
class EvalCase:
    id: str
    input: str
    expected: str
    notes: str | None = None


def load_cases(path: Path) -> list[EvalCase]:
    cases: list[EvalCase] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        cases.append(
            EvalCase(
                id=row["id"],
                input=row["input"],
                expected=row["expected"],
                notes=row.get("notes"),
            )
        )
    return cases


def main() -> None:
    try:
        openai_mod = importlib.import_module("openai")
        OpenAI = getattr(openai_mod, "OpenAI")
    except Exception as exc:
        raise SystemExit(
            "Missing dependency 'openai'. Install backend requirements and re-run. "
            f"Original error: {exc}"
        )

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise SystemExit("OPENAI_API_KEY is not set")

    model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.2"))

    # Use the same prompt as the backend would.
    system_prompt = os.getenv("EV_ASSISTANT_SYSTEM_PROMPT")
    if not system_prompt:
        # Fallback: read from backend config default (keeps script standalone).
        from app.core.config import get_settings

        system_prompt = get_settings().assistant_system_prompt

    client = OpenAI(api_key=api_key)

    eval_path = Path(__file__).resolve().parent / "ev_charging_eval.jsonl"
    cases = load_cases(eval_path)

    print(f"Running {len(cases)} evals with model={model} temperature={temperature}")
    print("----")

    for case in cases:
        resp = client.chat.completions.create(
            model=model,
            temperature=temperature,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": case.input},
            ],
        )
        text = (resp.choices[0].message.content or "").strip()

        print(f"[{case.id}] expected={case.expected}")
        if case.notes:
            print(f"notes: {case.notes}")
        print(f"user: {case.input}")
        print("assistant:")
        print(text)
        print("----")


if __name__ == "__main__":
    main()
