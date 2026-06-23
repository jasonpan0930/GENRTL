#!/usr/bin/env python3
"""Resolve RTLLM DUT module name for manifest / run context."""
from __future__ import annotations

import re
from pathlib import Path

_VERILOG_KEYWORDS = {
    "module",
    "endmodule",
    "initial",
    "always",
    "forever",
    "begin",
    "end",
    "if",
    "else",
    "case",
    "default",
    "assign",
    "wire",
    "reg",
    "integer",
    "parameter",
    "localparam",
    "posedge",
    "negedge",
    "or",
    "and",
    "not",
    "for",
    "while",
    "repeat",
    "fork",
    "join",
    "task",
    "function",
    "input",
    "output",
    "inout",
    "generate",
    "endgenerate",
}


def spec_module_from_text(text: str) -> str | None:
    m = re.search(r"Module name:\s*\n\s*(\S+)", text)
    return m.group(1) if m else None


def spec_module(problem_dir: Path) -> str | None:
    desc = problem_dir / "design_description.txt"
    if not desc.is_file():
        return None
    return spec_module_from_text(desc.read_text())


def makefile_module(problem_dir: Path) -> str:
    makefile = problem_dir / "makefile"
    if not makefile.is_file():
        return problem_dir.name
    m = re.search(r"^TEST_DESIGN\s*=\s*(\S+)", makefile.read_text(), re.M)
    return m.group(1) if m else problem_dir.name


def testbench_module(problem_dir: Path) -> str | None:
    tb = problem_dir / "testbench.v"
    if not tb.is_file():
        return None
    text = tb.read_text()
    patterns = [
        r"^\s*(\w+)\s*#\s*\([^)]*\)\s*(?:dut|DUT|uut|UUT)\s*\(",
        r"^\s*(\w+)\s+(?:dut|DUT|uut|UUT)\s*\(",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.M)
        if m and m.group(1) not in _VERILOG_KEYWORDS:
            return m.group(1)
    return None


def resolve_top_module(problem_dir: Path) -> str:
    """Prefer testbench DUT name, then SPEC, then makefile TEST_DESIGN."""
    return (
        testbench_module(problem_dir)
        or spec_module(problem_dir)
        or makefile_module(problem_dir)
    )
