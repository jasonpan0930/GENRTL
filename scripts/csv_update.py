#!/usr/bin/env python3
"""Init or upsert a row in experiments/results.csv."""
from __future__ import annotations

import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
_DEFAULT_CSV = ROOT / "experiments" / "results.csv"

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


def ensure_csv(path: Path | None = None) -> None:
    p = path or _DEFAULT_CSV
    p.parent.mkdir(parents=True, exist_ok=True)
    if not p.exists() or p.stat().st_size == 0:
        with p.open("w", newline="", encoding="utf-8") as f:
            csv.DictWriter(f, fieldnames=COLUMNS).writeheader()


def load_rows(path: Path | None = None) -> list[dict]:
    ensure_csv(path)
    p = path or _DEFAULT_CSV
    with p.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def row_key(row: dict) -> tuple[str, str]:
    return (row.get("problem_index", ""), row.get("workflow", ""))


def upsert(updates: dict, path: Path | None = None) -> None:
    p = path or _DEFAULT_CSV
    ensure_csv(p)
    rows = load_rows(p)
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
    with p.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)
    print(f"Updated {p} — index={updates['problem_index']} workflow={updates['workflow']}")


def main() -> None:
  # Usage: csv_update.py key=value ... [results_file=/path/to.csv]
    if len(sys.argv) < 2:
        raise SystemExit(f"Usage: {sys.argv[0]} problem_index=1 workflow=a gen_status=done ...")
    updates: dict = {}
    results_file: Path | None = None
    for arg in sys.argv[1:]:
        k, v = arg.split("=", 1)
        if k == "results_file":
            results_file = Path(v)
        elif k == "problem_index":
            updates[k] = int(v)
        else:
            updates[k] = v
    if "problem_index" not in updates or "workflow" not in updates:
        raise SystemExit("problem_index and workflow are required")
    upsert(updates, path=results_file)


if __name__ == "__main__":
    main()
