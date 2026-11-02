#!/usr/bin/env python3
"""Copy/check the runtime-neutral canonical files (work lifecycle, verification policy) from an explicit Claude root."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('.claude/agents/_shared/work-lifecycle.md')
DESTINATION = Path('plugins/codex-copilot/skills/cleanup/references/work-lifecycle.md')
POLICY_SOURCE = Path('.claude/agents/_shared/verification-policy.md')
POLICY_DESTINATION = Path('plugins/codex-copilot/skills/specialist-agents/references/verification-policy.md')
# Each canonical Claude file and its single byte-for-byte Codex copy.
PAIRS = ((SOURCE, DESTINATION), (POLICY_SOURCE, POLICY_DESTINATION))


def synchronize(claude_root: Path, codex_root: Path, *, check: bool = False,
                pair: tuple[Path, Path] = (SOURCE, DESTINATION)) -> bool:
    """Return equality in check mode; otherwise install one canonical file (default: the lifecycle)."""
    source = claude_root.resolve() / pair[0]
    destination = codex_root.resolve() / pair[1]
    if source.is_symlink() or not source.is_file():
        raise ValueError(f'Canonical file must be a regular file: {source}')
    content = source.read_bytes()
    if not content.strip():
        raise ValueError(f'Canonical file is empty: {source}')
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


def synchronize_all(claude_root: Path, codex_root: Path, *, check: bool = False) -> list[Path]:
    """Process every pair; return the destinations that differ (check mode) or were installed."""
    differing = []
    for pair in PAIRS:
        if not synchronize(claude_root, codex_root, check=check, pair=pair):
            differing.append(pair[1])
    return differing


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--claude-root', type=Path, required=True,
                        help='explicit source checkout; no installed/global discovery')
    parser.add_argument('--check', action='store_true', help='fail drift without writing')
    args = parser.parse_args()
    try:
        differing = synchronize_all(args.claude_root, ROOT, check=args.check)
    except (OSError, ValueError) as error:
        print(f'Canonical sync failed: {error}', file=sys.stderr)
        return 2
    if differing:
        for destination in differing:
            print(f'Canonical copy differs or is missing: {destination}', file=sys.stderr)
        return 1
    print('Canonical copies match the Claude source' if args.check else
          'Canonical copies synchronized: ' + ', '.join(str(d) for _, d in PAIRS))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
