#!/usr/bin/env python3
"""Validate Codex Copilot stream metadata before parallel work starts."""

from __future__ import annotations

import argparse
import fnmatch
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "lib"))
from validation_result import ValidationReport, failed, passed  # noqa: E402


REQUIRED_FIELDS = {"streamId", "files", "streamDependencies"}


def load_payload(path: str | None) -> list[dict[str, Any]]:
    raw = Path(path).read_text() if path else sys.stdin.read()
    payload = json.loads(raw)
    if isinstance(payload, dict):
        payload = payload.get("streams", [])
    if not isinstance(payload, list):
        raise ValueError("stream payload must be a list or an object with streams[]")
    return payload


def owned_paths(stream: dict[str, Any]) -> set[str]:
    paths = set(str(item) for item in stream.get("files", []))
    paths.update(str(item) for item in stream.get("streamPaths", []))
    return paths


def overlaps(a: str, b: str) -> bool:
    if a == b:
        return True
    if any(ch in a for ch in "*?[]") and fnmatch.fnmatch(b, a):
        return True
    if any(ch in b for ch in "*?[]") and fnmatch.fnmatch(a, b):
        return True
    return a.rstrip("/").startswith(b.rstrip("/") + "/") or b.rstrip("/").startswith(a.rstrip("/") + "/")


def validate(streams: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    ids: set[str] = set()

    for index, stream in enumerate(streams):
        missing = REQUIRED_FIELDS - set(stream)
        if missing:
            errors.append(f"stream {index} missing fields: {', '.join(sorted(missing))}")
            continue
        sid = str(stream["streamId"])
        if sid in ids:
            errors.append(f"duplicate streamId: {sid}")
        ids.add(sid)
        if not isinstance(stream.get("files"), list):
            errors.append(f"{sid}: files must be a list")
        if not isinstance(stream.get("streamDependencies"), list):
            errors.append(f"{sid}: streamDependencies must be a list")

    by_id = {str(stream.get("streamId")): stream for stream in streams}
    for sid, stream in by_id.items():
        for dep in stream.get("streamDependencies", []):
            if dep not in by_id:
                errors.append(f"{sid}: unknown dependency {dep}")

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(sid: str, stack: list[str]) -> None:
        if sid in visited:
            return
        if sid in visiting:
            errors.append("cycle detected: " + " -> ".join(stack + [sid]))
            return
        visiting.add(sid)
        for dep in by_id[sid].get("streamDependencies", []):
            if dep in by_id:
                visit(dep, stack + [sid])
        visiting.remove(sid)
        visited.add(sid)

    for sid in by_id:
        visit(sid, [])

    ids_list = list(by_id)
    for i, left_id in enumerate(ids_list):
        left_paths = owned_paths(by_id[left_id])
        for right_id in ids_list[i + 1 :]:
            for left in left_paths:
                for right in owned_paths(by_id[right_id]):
                    if overlaps(left, right):
                        errors.append(f"file ownership overlap: {left_id} {left} <-> {right_id} {right}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", help="JSON stream plan path; reads stdin when omitted")
    parser.add_argument("--json", action="store_true", help="emit machine-readable result")
    args = parser.parse_args()

    try:
        streams = load_payload(args.path)
        errors = validate(streams)
    except Exception as exc:  # noqa: BLE001 - script should report validation failures clearly
        errors = [str(exc)]

    checks = [
        failed("stream-validation", error, artifact=args.path or "stdin")
        for error in errors
    ] or [passed("stream-validation", f"{len(streams)} stream(s) valid", artifact=args.path or "stdin")]
    report = ValidationReport(checks=checks, context="orchestrate-validate")
    result = {"valid": not errors, "errors": errors, "report": report.to_dict()}
    if args.json:
        print(json.dumps(result, indent=2))
    elif errors:
        print("Stream validation failed:")
        for error in errors:
            print(f"- {error}")
    else:
        print(f"Stream validation passed ({len(streams)} stream(s))")
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
