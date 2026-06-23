#!/usr/bin/env python3
"""Audit RTLLM design_description.txt vs testbench.v consistency."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTLLM = Path(os.environ.get("RTLLM_ROOT", ROOT.parent / "RTLLM"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from manifest_lib import load_manifest  # noqa: E402
from rtllm_top_module import (  # noqa: E402
    makefile_module,
    resolve_top_module,
    spec_module_from_text,
    testbench_module,
)

STOP = re.compile(
    r"^(implementation|internal\s+logic|internal\s+signals|parameter|parameters|"
    r"registers\s+and\s+wires|give\s+me|behavior|memory\s+array|initial\s+block|"
    r"parameterized\s+values)",
    re.I,
)
INTERNAL_NOT_PORTS = {"res"}
POSITIONAL = {"float_multi", "alu", "pe", "LFSR"}
TB_PARAMS = {"Q", "N", "size", "DATA_WIDTH", "STG_WIDTH", "DEPTH", "WIDTH", "NUM_DIV"}


def parse_port_names_from_line(s: str) -> list[str]:
    names: list[str] = []
    if ":" in s:
        left, _, _ = s.partition(":")
        for part in left.split(","):
            part = part.strip()
            m = re.match(r"^([A-Za-z_][\w]*)(?:\[[^\]]*\])?$", part)
            if m:
                names.append(m.group(1))
        if names:
            return names
    m = re.match(r"^([A-Za-z_][\w]*)\s*(?:\[[^\]]*\])?\s*:", s)
    if m:
        names.append(m.group(1))
    m = re.match(r"^([A-Za-z_][\w]*)\s*\([^)]*(?:input|output)", s, re.I)
    if m:
        names.append(m.group(1))
    m = re.match(r"^\[([^\]]+)\]\s*([A-Za-z_][\w]*)\s*:", s)
    if m:
        names.append(m.group(2))
    return names


def spec_ports(text: str) -> tuple[set[str], set[str]]:
    ins: set[str] = set()
    outs: set[str] = set()
    sec: str | None = None
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        low = s.lower().replace("：", ":")
        if re.match(r"^inputs?:", low) or re.match(r"^input\s+ports?:", low):
            sec = "in"
            continue
        if re.match(r"^outputs?:", low) or re.match(r"^output\s+ports?:", low) or re.match(
            r"^output\s+port:", low
        ):
            sec = "out"
            continue
        if STOP.match(low):
            sec = None
            continue
        if sec:
            for n in parse_port_names_from_line(s):
                if n.lower() not in {"module", "on", "the", "if", "otherwise", "since", "when"}:
                    (ins if sec == "in" else outs).add(n)
    return ins, outs


def spec_parameters(text: str) -> set[str]:
    params: set[str] = set()
    in_params = False
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        low = s.lower().replace("：", ":")
        if re.match(
            r"^(parameters?|parameterized\s+values|input\s+parameters?):?\s*$",
            low,
        ):
            in_params = True
            continue
        if in_params and re.match(
            r"^(implementation|internal|input\s+ports?|output\s+ports?|give\s+me)",
            low,
        ):
            in_params = False
            continue
        if in_params:
            m = re.match(r"^([A-Za-z_][\w]*)\s*=", s)
            if m:
                params.add(m.group(1))
                continue
            m = re.match(r"^([A-Za-z_][\w]*)\s*:", s)
            if m:
                params.add(m.group(1))
    return params


def tb_named_ports(text: str) -> set[str]:
    return {m.group(1) for m in re.finditer(r"\.([A-Za-z_][\w]*)\s*\(", text)}


def tb_instance_params(text: str) -> set[str]:
    found: set[str] = set()
    for m in re.finditer(r"#\s*\((.*?)\)\s*[A-Za-z_]", text, re.S):
        block = m.group(1)
        for pm in re.finditer(r"\.([A-Za-z_][\w]*)\s*\(", block):
            found.add(pm.group(1))
    return found


def main() -> int:
    if not RTLLM.is_dir():
        raise SystemExit(f"RTLLM not found: {RTLLM}")

    manifest = {p["id"]: p for p in load_manifest()}
    errors: list[str] = []

    for desc in sorted(RTLLM.rglob("design_description.txt")):
        pid = desc.parent.name
        pdir = desc.parent
        idx = manifest[pid]["index"]
        text = desc.read_text()
        tbtext = (pdir / "testbench.v").read_text()

        spec_mod = spec_module_from_text(text)
        tb_mod = testbench_module(pdir)
        make_mod = makefile_module(pdir)
        resolved = resolve_top_module(pdir)

        if spec_mod and tb_mod and spec_mod != tb_mod:
            errors.append(f"#{idx} {pid}: module SPEC={spec_mod!r} TB={tb_mod!r}")
        if make_mod != resolved:
            errors.append(
                f"#{idx} {pid}: makefile TEST_DESIGN={make_mod!r} expected={resolved!r}"
            )

        if pid in POSITIONAL:
            continue

        si, so = spec_ports(text)
        spec_p = (si | so) - INTERNAL_NOT_PORTS
        spec_params = spec_parameters(text)
        tb_p = tb_named_ports(tbtext) - tb_instance_params(tbtext)
        only_spec = spec_p - tb_p
        only_tb = tb_p - spec_p

        if only_spec or only_tb:
            errors.append(
                f"#{idx} {pid}: ports SPEC-only={sorted(only_spec)} TB-only={sorted(only_tb)}"
            )

        undocumented = tb_instance_params(tbtext) - spec_params
        if undocumented:
            errors.append(
                f"#{idx} {pid}: TB parameters not in SPEC: {sorted(undocumented)}"
            )

    if errors:
        print("SPEC/TB audit FAILED:", file=sys.stderr)
        for e in errors:
            print(e, file=sys.stderr)
        return 1

    print(f"SPEC/TB audit OK ({len(manifest)} problems)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
