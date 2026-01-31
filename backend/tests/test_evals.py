from __future__ import annotations

import json
from pathlib import Path


def test_eval_set_is_valid_jsonl_and_has_core_cases():
    eval_path = Path(__file__).resolve().parents[1] / "evals" / "ev_charging_eval.jsonl"
    assert eval_path.exists(), "Missing eval set file: backend/evals/ev_charging_eval.jsonl"

    ids: set[str] = set()
    inputs: list[str] = []

    for line in eval_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        assert set(row.keys()) >= {"id", "input", "expected"}
        assert isinstance(row["id"], str) and row["id"].strip()
        assert isinstance(row["input"], str) and row["input"].strip()
        assert row["expected"] in {"ANSWER", "ASK_CLARIFY", "REFUSE"}

        assert row["id"] not in ids, f"Duplicate eval id: {row['id']}"
        ids.add(row["id"])
        inputs.append(row["input"].strip().lower())

