#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from manifest_lib import resolve  # noqa: E402


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(f"Usage: {sys.argv[0]} <index|problem_id>")
    print(json.dumps(resolve(sys.argv[1]), indent=2))


if __name__ == "__main__":
    main()
