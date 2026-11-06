"""Helpers for central-resolution tests: a stub `cc` and a fake release pointer.

Tests must never touch the real ~/.codex, ~/.copilot or real projects; everything
lives under a caller-supplied temporary directory.
"""
import os
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

_STUB = r"""#!/bin/bash
# Stub cc: records calls, mimics `cc project init` writes (marker + AGENTS section).
echo "$*" >> "$(dirname "$0")/cc-calls.log"
if [ "$1" = project ] && [ "$2" = init ]; then
  p="$3"
  printf '{"runtimes":["claude","codex"]}\n' > "$p/copilot.project.json"
  grep -q 'copilot:framework-section' "$p/AGENTS.md" 2>/dev/null || \
    printf '<!-- copilot:framework-section:begin v1 -->\n## Copilot\n<!-- copilot:framework-section:end -->\n' >> "$p/AGENTS.md"
  exit 0
fi
[ "$1" = doctor ] && { echo "doctor ok"; exit 0; }
exit 2
"""


def stub_cc(directory) -> Path:
    path = Path(directory) / "cc"
    path.write_text(_STUB)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


def link_central_release(home: Path) -> None:
    """Fake ~/.copilot/current/codex-copilot -> this checkout under a temp HOME."""
    current = Path(home) / ".copilot" / "current"
    current.mkdir(parents=True)
    (current / "codex-copilot").symlink_to(ROOT)


def env_with(home: Path, **extra) -> dict:
    return {**os.environ, "HOME": str(home), **extra}
