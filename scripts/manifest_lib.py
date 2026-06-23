#!/usr/bin/env python3
"""Parse benchmarks/rtllm_manifest.yaml without external deps."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "benchmarks" / "rtllm_manifest.yaml"


def load_manifest() -> list[dict]:
    text = MANIFEST.read_text()
    problems: list[dict] = []
    cur: dict | None = None
    for line in text.splitlines():
        m = re.match(r"\s+-\s+index:\s+(\d+)", line)
        if m:
            if cur:
                problems.append(cur)
            cur = {"index": int(m.group(1))}
            continue
        if cur is None:
            continue
        for key in ("id", "path", "top_module"):
            m2 = re.match(rf"\s+{key}:\s+(.+)", line)
            if m2:
                val = m2.group(1).strip()
                if key == "index":
                    cur[key] = int(val)
                else:
                    cur[key] = val
    if cur:
        problems.append(cur)
    return problems


def resolve(query: str) -> dict:
    problems = load_manifest()
    if query.isdigit():
        idx = int(query)
        for p in problems:
            if p["index"] == idx:
                return p
        raise SystemExit(f"No problem with index {idx} (valid: 1–{len(problems)})")
    q = query.lower()
    for p in problems:
        if p["id"].lower() == q:
            return p
    raise SystemExit(f"No problem with id '{query}'")
