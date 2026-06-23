#!/usr/bin/env python3
"""Init or upsert a row in experiments/results.csv."""
from __future__ import annotations

import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "experiments" / "results.csv"

COLUMNS = [
    "problem_index",
    "problem_id",
    "rtllm_path",
    "top_module",
    "workflow",
    "model",
    "skill",
    "spec_path",
    "rtl_path",
    "rtl_archived",
    "gen_status",
    "vcs_compile",
    "vcs_sim",
    "sim_message",
    "notes",
    "updated_at",
]


def ensure_csv() -> None:
    CSV_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not CSV_PATH.exists() or CSV_PATH.stat().st_size == 0:
        with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
            csv.DictWriter(f, fieldnames=COLUMNS).writeheader()


def load_rows() -> list[dict]:
    ensure_csv()
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def row_key(row: dict) -> tuple[str, str]:
    return (row.get("problem_index", ""), row.get("workflow", ""))


def upsert(updates: dict) -> None:
    ensure_csv()
    rows = load_rows()
    key = (str(updates["problem_index"]), updates["workflow"])
    found = False
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    for row in rows:
        if row_key(row) == key:
            row.update({k: str(v) for k, v in updates.items() if v is not None})
            row["updated_at"] = now
            found = True
            break
    if not found:
        base = {c: "" for c in COLUMNS}
        base.update({k: str(v) for k, v in updates.items()})
        base["updated_at"] = now
        rows.append(base)
    with CSV_PATH.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)
    print(f"Updated {CSV_PATH} — index={updates['problem_index']} workflow={updates['workflow']}")


def main() -> None:
  # Usage: csv_update.py key=value ...
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} problem_index=1 workflow=a gen_status=done ...")
    updates: dict = {}
    for arg in sys.argv[1:]:
        k, v = arg.split("=", 1)
        if k == "problem_index":
            updates[k] = int(v)
        else:
            updates[k] = v
    if "problem_index" not in updates or "workflow" not in updates:
        raise SystemExit("problem_index and workflow are required")
    upsert(updates)


if __name__ == "__main__":
    main()
