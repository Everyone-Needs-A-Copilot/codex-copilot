#!/usr/bin/env python3
"""Compare the adopted parity baseline with an available Claude checkout."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def find_upstream(explicit: str | None) -> Path | None:
    candidates = [
        explicit,
        os.environ.get("CLAUDE_COPILOT_ROOT"),
        str(ROOT.parent / "claude-copilot"),
    ]
    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate).expanduser().resolve()
        if (path / "VERSION.json").is_file():
            return path
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--upstream")
    parser.add_argument("--require", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    upstream = find_upstream(args.upstream)
    if upstream is None:
        result = {"status": "skipped", "reason": "Claude Copilot VERSION.json not available"}
        print(json.dumps(result) if args.json else f"Upstream parity skipped: {result['reason']}")
        return 1 if args.require else 0

    adopted = json.loads((ROOT / "VERSION.json").read_text())
    source = json.loads((upstream / "VERSION.json").read_text())
    expected = {
        "framework": adopted["mirrors"]["frameworkVersion"],
        "cc": adopted["components"]["cc"]["requiredVersion"],
        "tc": adopted["components"]["tc"]["requiredVersion"],
    }
    actual = {
        "framework": source["framework"],
        "cc": source["components"]["cc"]["version"],
        "tc": source["components"]["tc"]["version"],
    }
    mismatches = {
        key: {"adopted": expected[key], "upstream": actual[key]}
        for key in expected
        if expected[key] != actual[key]
    }
    result = {
        "status": "fail" if mismatches else "pass",
        "upstream": str(upstream),
        "mismatches": mismatches,
    }
    if args.json:
        print(json.dumps(result, indent=2))
    elif mismatches:
        print("Upstream parity failed:")
        for key, values in mismatches.items():
            print(f"- {key}: adopted {values['adopted']} != upstream {values['upstream']}")
    else:
        print(
            "Upstream parity passed "
            f"(Claude {actual['framework']}, cc {actual['cc']}, tc {actual['tc']})"
        )
    return 1 if mismatches else 0


if __name__ == "__main__":
    raise SystemExit(main())
