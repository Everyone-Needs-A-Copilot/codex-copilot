#!/usr/bin/env python3
"""Source-checkout compatibility wrapper for the installed native adapter."""
from pathlib import Path
import runpy

BUNDLED = Path(__file__).resolve().parents[1] / "plugins/codex-copilot/scripts/protocol-cycle.py"
_adapter = runpy.run_path(str(BUNDLED))
role_ids = _adapter["role_ids"]
main = _adapter["main"]

if __name__ == "__main__":
    raise SystemExit(main())
