#!/usr/bin/env python3
"""Activate a dormant Codex Copilot pack in a project-local plugin."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def rel_symlink(target: Path, link: Path) -> None:
    if link.exists() or link.is_symlink():
        raise FileExistsError(f"Refusing to replace existing path: {link}")
    link.parent.mkdir(parents=True, exist_ok=True)
    rel = os.path.relpath(target.resolve(), link.parent.resolve())
    link.symlink_to(rel)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="target project directory")
    parser.add_argument("--pack", required=True, help="pack name under packs/")
    parser.add_argument("--framework-root", default=str(ROOT), help="codex-copilot framework root")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    framework = Path(args.framework_root).resolve()
    project = Path(args.project).resolve()
    pack = framework / "packs" / args.pack
    manifest = pack / "pack.json"
    if not project.is_dir():
        raise SystemExit(f"Project path does not exist: {project}")
    if not manifest.exists():
        raise SystemExit(f"Pack manifest not found: {manifest}")

    data = json.loads(manifest.read_text())
    skills_dir = pack / "skills"
    if not skills_dir.is_dir():
        raise SystemExit(f"Pack skills directory not found: {skills_dir}")

    link = project / ".claude" / "skills" / args.pack
    rel_symlink(skills_dir, link)

    marketplace = project / ".agents" / "plugins" / f"{args.pack}.json"
    marketplace.parent.mkdir(parents=True, exist_ok=True)
    if marketplace.exists():
        raise SystemExit(f"Refusing to overwrite existing marketplace entry: {marketplace}")
    marketplace.write_text(
        json.dumps(
            {
                "name": f"codex-copilot-{args.pack}",
                "interface": {"displayName": data.get("displayName", args.pack)},
                "skills": str(link),
                "pack": data,
            },
            indent=2,
        )
        + "\n"
    )

    result = {"pack": args.pack, "skillLink": str(link), "marketplace": str(marketplace)}
    print(json.dumps(result, indent=2) if args.json else f"Activated {args.pack}: {link}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
