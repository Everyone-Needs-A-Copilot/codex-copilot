#!/usr/bin/env python3
"""Copy/check only the runtime-neutral lifecycle from an explicit Claude root."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('.claude/agents/_shared/work-lifecycle.md')
DESTINATION = Path('plugins/codex-copilot/skills/optimize/references/work-lifecycle.md')


def synchronize(claude_root: Path, codex_root: Path, *, check: bool = False) -> bool:
    """Return equality in check mode; otherwise install the one canonical file."""
    source = claude_root.resolve() / SOURCE
    destination = codex_root.resolve() / DESTINATION
    if source.is_symlink() or not source.is_file():
        raise ValueError(f'Canonical lifecycle must be a regular file: {source}')
    content = source.read_bytes()
    if not content.strip():
        raise ValueError(f'Canonical lifecycle is empty: {source}')
    if destination.is_symlink() or not destination.resolve().is_relative_to(codex_root.resolve()):
        raise ValueError(f'Refusing a redirected destination: {destination}')
    if destination.exists() and not destination.is_file():
        raise ValueError(f'Destination is not a regular file: {destination}')
    matches = destination.is_file() and destination.read_bytes() == content
    if check:
        return matches
    if not matches:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--claude-root', type=Path, required=True,
                        help='explicit source checkout; no installed/global discovery')
    parser.add_argument('--check', action='store_true', help='fail drift without writing')
    args = parser.parse_args()
    try:
        matches = synchronize(args.claude_root, ROOT, check=args.check)
    except (OSError, ValueError) as error:
        print(f'Lifecycle sync failed: {error}', file=sys.stderr)
        return 2
    if not matches:
        print(f'Lifecycle reference differs or is missing: {DESTINATION}', file=sys.stderr)
        return 1
    print('Lifecycle reference matches canonical source' if args.check else
          f'Lifecycle reference synchronized: {DESTINATION}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
