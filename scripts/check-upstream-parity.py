#!/usr/bin/env python3
"""Compare the adopted parity baseline with an available Claude checkout.

Two independent checks live here:

- Version-string parity (default): compares the three top-level version
  strings the adopted baseline pins (framework/cc/tc) against the upstream
  checkout. This is the original, unchanged contract.
- Content-level parity (``--content``): hashes every upstream file that
  defines shared behavior (agents, commands, skill definitions) plus
  Claude Copilot's independently-versioned agents/commands fields, and
  compares against a committed manifest (``parity/upstream-content-hashes.json``).
  Claude Copilot bumps its agents/commands version fields independently of
  the framework string, so a content change that doesn't bump the framework
  version passes the version-only check while still diverging in substance.
  ``--content`` exists to make that drift visible.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONTENT_BASELINE = ROOT / "parity" / "upstream-content-hashes.json"
DEFAULT_UPDATE_LOG = ROOT / "parity" / "baseline-update-log.json"

# Relative (to the upstream checkout root) glob patterns for every file that
# defines shared, mirrored behavior. Order is significant only for readability;
# results are always sorted before use.
CONTENT_GLOB_PATTERNS = [
    ".claude/agents/*.md",
    ".claude/commands/*.md",
    ".claude/skills/**/SKILL.md",
]

# VERSION.json fields that version independently of the top-level framework
# string. "skills" also versions independently but isn't part of this audit's
# scope; add it here if a future sweep needs it tracked too.
CONTENT_VERSION_FIELDS = ["framework", "agents", "commands"]


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


def upstream_commit(upstream: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(upstream), "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return None
    return result.stdout.strip() or None


def collect_content_files(upstream: Path) -> dict[str, str]:
    """Return {relpath: sha256} for every shared-behavior file that exists."""
    files: dict[str, str] = {}
    for pattern in CONTENT_GLOB_PATTERNS:
        for path in sorted(upstream.glob(pattern)):
            if not path.is_file():
                continue
            rel = path.relative_to(upstream).as_posix()
            files[rel] = hashlib.sha256(path.read_bytes()).hexdigest()
    return files


def collect_content_versions(upstream: Path) -> dict[str, str | None]:
    version_path = upstream / "VERSION.json"
    if not version_path.is_file():
        return {field: None for field in CONTENT_VERSION_FIELDS}
    data = json.loads(version_path.read_text())
    components = data.get("components", {})
    versions: dict[str, str | None] = {"framework": data.get("framework")}
    for field in CONTENT_VERSION_FIELDS:
        if field == "framework":
            continue
        versions[field] = components.get(field, {}).get("version")
    return versions


def build_content_manifest(upstream: Path) -> dict:
    return {
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "upstream_commit": upstream_commit(upstream),
        "files": collect_content_files(upstream),
        "versions": collect_content_versions(upstream),
    }


def load_content_baseline(baseline_path: Path) -> dict | None:
    if not baseline_path.is_file():
        return None
    return json.loads(baseline_path.read_text())


def diff_content(baseline: dict, current: dict) -> dict:
    baseline_files = baseline.get("files", {})
    current_files = current.get("files", {})

    changed = sorted(
        rel
        for rel in baseline_files.keys() & current_files.keys()
        if baseline_files[rel] != current_files[rel]
    )
    added = sorted(current_files.keys() - baseline_files.keys())
    removed = sorted(baseline_files.keys() - current_files.keys())

    baseline_versions = baseline.get("versions", {})
    current_versions = current.get("versions", {})
    version_diffs = {
        field: {"baseline": baseline_versions.get(field), "upstream": current_versions.get(field)}
        for field in sorted(set(baseline_versions) | set(current_versions))
        if baseline_versions.get(field) != current_versions.get(field)
    }

    status = "drift" if (changed or added or removed or version_diffs) else "pass"
    return {
        "status": status,
        "changed": changed,
        "added": added,
        "removed": removed,
        "version_diffs": version_diffs,
        "baseline_upstream_commit": baseline.get("upstream_commit"),
        "current_upstream_commit": current.get("upstream_commit"),
        "file_count": len(current_files),
    }


def codex_repo_head(codex_root: Path) -> str | None:
    """HEAD commit of codex-copilot ITSELF (never the upstream checkout) --
    recorded purely for audit provenance in the update log; NOT used as port
    evidence. A "HEAD moved since the last recorded update" signal was
    tried and rejected (see run_update_baseline's docstring/comment): it let
    a prior, unrelated port commit silently unlock resolving a later,
    different drift it had nothing to do with."""
    try:
        result = subprocess.run(
            ["git", "-C", str(codex_root), "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return None
    return result.stdout.strip() or None


def codex_repo_dirty(codex_root: Path, baseline_path: Path) -> bool:
    """True if codex-copilot's own working tree has an uncommitted change to
    any TRACKED file OUTSIDE parity/ (the content baseline manifest and the
    update log are this script's own bookkeeping output -- the very update
    being guarded is expected to rewrite them, so their own diff can't count
    as evidence that a mirrored-surface port happened)."""
    try:
        result = subprocess.run(
            ["git", "-C", str(codex_root), "status", "--porcelain"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return False
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        # porcelain v1: "XY <path>" (renames: "XY <old> -> <new>")
        changed_path = line[3:].split(" -> ")[-1].strip().strip('"')
        if changed_path.startswith("parity/"):
            continue
        return True
    return False


def run_update_baseline(
    upstream: Path | None,
    baseline_path: Path,
    use_json: bool,
    codex_root: Path = ROOT,
    update_log_path: Path = DEFAULT_UPDATE_LOG,
    attest_no_port_needed: str | None = None,
) -> int:
    if upstream is None:
        reason = "Claude Copilot VERSION.json not available; cannot update content baseline"
        print(json.dumps({"status": "error", "reason": reason}) if use_json else reason)
        return 1

    manifest = build_content_manifest(upstream)
    old_baseline = load_content_baseline(baseline_path)

    # Port guard (fixes the "re-baselining alone silently resolves drift"
    # trust gap): if the OLD baseline already existed and shows real content
    # drift against the freshly-hashed upstream, --update-baseline must not
    # be able to mark that drift resolved unless codex-copilot's own working
    # tree has an uncommitted change RIGHT NOW outside parity/ -- the exact
    # "port the mirrored surface, then run --update-baseline before
    # committing both together" flow this repo's own history already uses
    # (commit ce087be1: the shared-behaviors.md port was staged/unstaged
    # when --update-baseline ran, then both landed in one commit). A
    # candidate "HEAD moved since the last recorded update" signal was
    # tried and REJECTED here (see git history of this function): it let a
    # PRIOR, unrelated port commit silently "unlock" resolving a completely
    # different, later drift that was never actually ported -- a real
    # instance of exactly the fabrication-resistance gap this guard exists
    # to close, caught by this file's own regression tests, not by
    # inspection. Absent live evidence, the update is refused unless the
    # caller explicitly attests nothing needed porting (recorded, never
    # silent) -- e.g. a pure renumbering/comment-only upstream change with
    # no codex-side mirror to touch.
    if old_baseline is not None:
        drift = diff_content(old_baseline, manifest)
        has_drift = bool(drift["changed"] or drift["added"] or drift["removed"])
        if has_drift:
            dirty = codex_repo_dirty(codex_root, baseline_path)
            head = codex_repo_head(codex_root)
            if not dirty and not attest_no_port_needed:
                reason = (
                    "REFUSING to update the content baseline: upstream content drift was "
                    f"detected ({len(drift['changed'])} changed, {len(drift['added'])} added, "
                    f"{len(drift['removed'])} removed: {sorted(drift['changed'] + drift['added'] + drift['removed'])}) "
                    "but codex-copilot's own working tree has no corresponding uncommitted change "
                    "outside parity/ right now -- nothing appears to have been ported. Port the change "
                    "into codex-copilot's mirrored surface first (leave it staged/unstaged), then "
                    "re-run --update-baseline so the port and the baseline resync land together; if this "
                    "drift genuinely needs no port (e.g. a pure renumbering/comment-only upstream change), "
                    "re-run with --attest-no-port-needed \"<reason>\" to record that decision explicitly "
                    "rather than resolving it silently."
                )
                result = {
                    "status": "refused",
                    "reason": reason,
                    "drift": drift,
                    "codex_working_tree_dirty": dirty,
                    "codex_head_commit": head,
                }
                print(json.dumps(result, indent=2) if use_json else reason)
                return 1

    baseline_path.parent.mkdir(parents=True, exist_ok=True)
    baseline_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    log_entry = {
        "updated_at": manifest["generated_at"],
        "upstream_commit": manifest["upstream_commit"],
        "codex_head_commit": codex_repo_head(codex_root),
        "codex_working_tree_dirty_at_update": codex_repo_dirty(codex_root, baseline_path),
        "port_attestation": attest_no_port_needed,
    }
    update_log_path.parent.mkdir(parents=True, exist_ok=True)
    update_log_path.write_text(json.dumps(log_entry, indent=2, sort_keys=True) + "\n")

    result = {
        "status": "updated",
        "upstream": str(upstream),
        "baseline": str(baseline_path),
        "file_count": len(manifest["files"]),
        "upstream_commit": manifest["upstream_commit"],
        "port_guard": log_entry,
    }
    if use_json:
        print(json.dumps(result, indent=2))
    else:
        print(
            f"Updated content baseline: {result['file_count']} files "
            f"@ {result['upstream_commit'] or 'unknown commit'} -> {baseline_path}"
        )
        print(
            f"Port guard: codex HEAD {log_entry['codex_head_commit']}, "
            f"working tree dirty at update: {log_entry['codex_working_tree_dirty_at_update']}"
            + (f", attestation: {log_entry['port_attestation']!r}" if attest_no_port_needed else "")
        )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--upstream")
    parser.add_argument("--require", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--content",
        action="store_true",
        help="Also run content-level hash parity against the committed content baseline",
    )
    parser.add_argument(
        "--update-baseline",
        action="store_true",
        help="Regenerate the content baseline manifest from the current upstream checkout and exit",
    )
    parser.add_argument(
        "--baseline",
        help="Override the content baseline manifest path (default: parity/upstream-content-hashes.json)",
    )
    parser.add_argument(
        "--update-log",
        help="Override the port-guard update-log path (default: parity/baseline-update-log.json)",
    )
    parser.add_argument(
        "--attest-no-port-needed",
        metavar="REASON",
        help=(
            "Required to force --update-baseline through the port guard when upstream content "
            "drifted but codex-copilot's own repo shows no corresponding change (working tree "
            "clean, HEAD unmoved since the last recorded update). Records REASON in the update "
            "log instead of resolving the drift silently."
        ),
    )
    parser.add_argument(
        "--codex-root",
        help="Override which git repo is treated as 'codex-copilot itself' for the port guard's "
        "working-tree/HEAD checks (default: this script's own repo root). Test-only escape hatch; "
        "production use should rely on the default.",
    )
    args = parser.parse_args()

    baseline_path = Path(args.baseline).expanduser().resolve() if args.baseline else DEFAULT_CONTENT_BASELINE
    update_log_path = Path(args.update_log).expanduser().resolve() if args.update_log else DEFAULT_UPDATE_LOG
    codex_root = Path(args.codex_root).expanduser().resolve() if args.codex_root else ROOT
    upstream = find_upstream(args.upstream)

    if args.update_baseline:
        return run_update_baseline(
            upstream,
            baseline_path,
            args.json,
            codex_root=codex_root,
            update_log_path=update_log_path,
            attest_no_port_needed=args.attest_no_port_needed,
        )

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

    content_failed = False
    if args.content:
        current_manifest = build_content_manifest(upstream)
        content_baseline = load_content_baseline(baseline_path)
        if content_baseline is None:
            result["content"] = {
                "status": "error",
                "reason": f"content baseline not found at {baseline_path}; run --update-baseline",
            }
            content_failed = True
        else:
            content_result = diff_content(content_baseline, current_manifest)
            result["content"] = content_result
            content_failed = content_result["status"] == "drift"

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if mismatches:
            print("Upstream parity failed:")
            for key, values in mismatches.items():
                print(f"- {key}: adopted {values['adopted']} != upstream {values['upstream']}")
        else:
            print(
                "Upstream parity passed "
                f"(Claude {actual['framework']}, cc {actual['cc']}, tc {actual['tc']})"
            )
        if args.content:
            content = result["content"]
            if content["status"] == "error":
                print(f"Content parity error: {content['reason']}")
            elif content["status"] == "drift":
                print("Content parity drift detected:")
                for label in ("changed", "added", "removed"):
                    for item in content[label]:
                        print(f"- {label}: {item}")
                for field, diff in content["version_diffs"].items():
                    print(f"- version:{field}: baseline {diff['baseline']} != upstream {diff['upstream']}")
            else:
                print(f"Content parity passed ({content['file_count']} files hashed)")

    return 1 if (mismatches or content_failed) else 0


if __name__ == "__main__":
    raise SystemExit(main())
