#!/usr/bin/env bash
# Fail closed for changed grading files unless an exact reviewed receipt is supplied.
# Validates receipt freshness/completeness, not user authority or QA approval.
# Usage: check-test-integrity.sh [base-ref] [--test-change-receipt receipt.json]
set -euo pipefail
exec python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def fail(message):
    print(f"TEST INTEGRITY FAILED — {message}", file=sys.stderr)
    raise SystemExit(1)


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True)
    if result.returncode:
        fail("cannot inspect git state; verify repository and comparison base")
    return result.stdout


def digest(content):
    return hashlib.sha256(content).hexdigest()


def text(value):
    return isinstance(value, str) and bool(value.strip())


def local_file(root, name):
    if not text(name) or Path(name).is_absolute() or ".." in Path(name).parts:
        fail("receipt paths must be repository-relative, without traversal")
    path = root / name
    if not path.resolve().is_relative_to(root) or path.is_symlink():
        fail("receipt path escapes repository or names a symlink")
    return path


parser = argparse.ArgumentParser(description="Review exact test changes, never grant QA approval")
parser.add_argument("base", nargs="?", default="HEAD")
parser.add_argument("--test-change-receipt")
args = parser.parse_args()
if args.base.startswith("-"):
    fail("invalid comparison base")
root = Path(git("rev-parse", "--show-toplevel").decode().strip()).resolve()
os.chdir(root)
base = git("rev-parse", "--verify", args.base + "^{commit}").decode().strip()
pattern = re.compile(r"(^|/)(test_[^/]*\.py|[^/]*_test\.py|[^/]*\.test\.[jt]sx?|[^/]*\.spec\.[jt]sx?)$|(^|/)tests?/")
changes = set()
for raw in (
    git("diff", "--no-ext-diff", "--name-only", "--no-renames", "-z", base, "--"),
    git("diff", "--no-ext-diff", "--cached", "--name-only", "--no-renames", "-z", base, "--"),
    git("ls-files", "--others", "--exclude-standard", "-z"),
):
    changes.update(p.decode() for p in raw.split(b"\0") if p and pattern.search(p.decode()))
if not changes:
    print("test integrity ok — no graded file was modified")
    raise SystemExit(0)
if not args.test_change_receipt:
    fail("grading files changed without a reviewed test-change receipt: " + ", ".join(sorted(changes)))

try:
    receipt = json.loads(Path(args.test_change_receipt).read_text())
    if not isinstance(receipt, dict) or receipt.get("schemaVersion") != 1:
        fail("unsupported receipt schema")
    for key in ("task", "authorizationRef", "rationale", "oldExpectation", "newExpectation"):
        if not text(receipt.get(key)):
            fail("receipt missing " + key)
    if receipt.get("baseCommit") != base:
        fail("receipt comparison base is stale")
    entries = receipt.get("changes")
    if not isinstance(entries, list) or any(not isinstance(e, dict) for e in entries):
        fail("receipt changes must be an exact list")
    paths = [e.get("path") for e in entries]
    if any(not text(p) for p in paths) or len(set(paths)) != len(paths) or set(paths) != changes:
        fail("receipt changed-file set does not match")
    for entry in entries:
        name = entry["path"]
        path = local_file(root, name)
        before = subprocess.run(["git", "show", f"{base}:{name}"], capture_output=True)
        index = subprocess.run(["git", "show", f":{name}"], capture_output=True)
        expected = {
            "beforeSha256": digest(before.stdout) if before.returncode == 0 else None,
            "indexSha256": digest(index.stdout) if index.returncode == 0 else None,
            "afterSha256": digest(path.read_bytes()) if path.is_file() else None,
        }
        if any(k not in entry or entry[k] != v for k, v in expected.items()):
            fail("receipt content is stale for " + name)
        if not text(entry.get("assertions")):
            fail("receipt must describe the exact changed assertions for " + name)
    diffs = [git("diff", "--no-ext-diff", "--no-textconv", "--binary", "--no-renames", *extra, base, "--", *sorted(changes)).hex()
             for extra in ([], ["--cached"])]
    if receipt.get("diffSha256") != digest(json.dumps(diffs, separators=(",", ":")).encode()):
        fail("receipt exact test diff is stale")
    control = receipt.get("negativeControl")
    if not isinstance(control, dict):
        fail("receipt missing negative control")
    command = control.get("command")
    if not isinstance(command, list) or not command or any(not text(a) for a in command):
        fail("negative control must name a failable command argument array")
    if type(control.get("exitCode")) is not int or control["exitCode"] <= 0:
        fail("negative control must record rejection of the targeted broken behavior")
    if not text(control.get("rejectedBehavior")):
        fail("negative control must explain the rejected behavior")
    artifact = local_file(root, control.get("path"))
    if not artifact.is_file() or not artifact.stat().st_size or control.get("sha256") != digest(artifact.read_bytes()):
        fail("negative-control artifact is missing, empty or stale")
except (OSError, ValueError, TypeError, KeyError) as exc:
    fail("invalid or unreadable receipt: " + str(exc))

print("test-change receipt matches exact content — QA must review authority, assertions and negative-control evidence; tc approval is still required")
PY
