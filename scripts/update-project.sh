#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  update-project.sh --project /path/to/project [options]

Options:
  --project PATH          Target project directory (must already be set up
                           by setup-project.sh)
  --framework-root PATH   Override detected codex-copilot framework root
  --dry-run               Report what would change without writing anything
  --help                  Show this help

Refreshes an EXISTING codex-copilot install in place. The framework-owned
files under plugins/codex-copilot/ (61 files) plus scripts/copilot-gate.sh
(1 file) -- 62 locked paths total -- are compared BY CONTENT (sha256, not by
declared version) against the framework source and repaired when they
differ, including drift that carries bytes from an intermediate commit
rather than a released version.

Framework source resolution (when --framework-root is not given): the
pinned mirror at ~/.copilot/mirrors/codex-foundation is used if it looks
like a valid framework checkout (this matches cc's own
paths.codex_copilot_root default, and is what every consumer's --project
run should sync against -- never a live, possibly-ahead-of-release dev
checkout). Only when no pinned mirror is present does this fall back to
self-locating relative to this script (the framework repo's own copy),
which is what makes running this script from within a codex-copilot dev
checkout still work for local testing.

A file is never touched if it is marked ownership: project, either via
`owner: project` YAML frontmatter inside the file itself, or via a
`copilot.lock.json` entry for that path with "ownership": "project". This
mirrors the owner: project convention Claude Copilot projects already use
to protect hand-authored content, applied to the codex plugin tree.

Idempotent: running this twice in a row makes no further changes on the
second run. Never destructive outside the 62 locked paths -- AGENTS.md,
SOUL.md, docs/40-initiatives/, marketplace.json, and install metadata are
untouched (or, for install metadata, only field-merged, never replaced).

Run setup-project.sh first if the project has never been set up.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF_LOCATED_FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_MIRROR_ROOT="${HOME}/.copilot/mirrors/codex-foundation"
FRAMEWORK_ROOT="${SELF_LOCATED_FRAMEWORK_ROOT}"
FRAMEWORK_ROOT_EXPLICIT=0

PROJECT_PATH=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_PATH="${2:-}"
      shift 2
      ;;
    --framework-root)
      FRAMEWORK_ROOT="$(cd "${2:-}" && pwd)"
      FRAMEWORK_ROOT_EXPLICIT=1
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${PROJECT_PATH}" ]]; then
  echo "--project is required" >&2
  usage >&2
  exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Project path does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi
PROJECT_PATH="$(cd "${PROJECT_PATH}" && pwd)"

# Prefer the pinned mirror over a self-located dev checkout unless the
# caller was explicit -- this is the whole fix for repos ending up with
# plugin content newer than any release: an ad-hoc `update-project.sh
# --project <path>` run from inside the framework repo must not silently
# source from wherever it happens to be checked out.
FRAMEWORK_ROOT_SOURCE="explicit --framework-root (${FRAMEWORK_ROOT})"
if [[ "${FRAMEWORK_ROOT_EXPLICIT}" -eq 0 ]]; then
  if [[ -d "${DEFAULT_MIRROR_ROOT}/plugins/codex-copilot" && -f "${DEFAULT_MIRROR_ROOT}/scripts/copilot-gate.sh" ]]; then
    FRAMEWORK_ROOT="${DEFAULT_MIRROR_ROOT}"
    FRAMEWORK_ROOT_SOURCE="pinned mirror (${DEFAULT_MIRROR_ROOT})"
  else
    FRAMEWORK_ROOT_SOURCE="self-located framework checkout (${SELF_LOCATED_FRAMEWORK_ROOT}; no pinned mirror found at ${DEFAULT_MIRROR_ROOT})"
  fi
fi

FRAMEWORK_PLUGIN_PATH="${FRAMEWORK_ROOT}/plugins/codex-copilot"
FRAMEWORK_QA_GATE_PATH="${FRAMEWORK_ROOT}/scripts/copilot-gate.sh"

if [[ ! -d "${FRAMEWORK_PLUGIN_PATH}" ]]; then
  echo "Missing framework plugin directory: ${FRAMEWORK_PLUGIN_PATH}" >&2
  exit 1
fi

if [[ ! -f "${FRAMEWORK_QA_GATE_PATH}" ]]; then
  echo "Missing framework QA gate: ${FRAMEWORK_QA_GATE_PATH}" >&2
  exit 1
fi

PLUGIN_LINK="${PROJECT_PATH}/plugins/codex-copilot"
CODEX_CONFIG_PATH="${PROJECT_PATH}/.codex-copilot.json"

if [[ ! -e "${PLUGIN_LINK}" && ! -f "${CODEX_CONFIG_PATH}" ]]; then
  echo "No existing codex-copilot install found at: ${PROJECT_PATH}" >&2
  echo "Run scripts/setup-project.sh --project ${PROJECT_PATH} first." >&2
  exit 1
fi

if [[ -L "${PLUGIN_LINK}" ]]; then
  echo "plugins/codex-copilot is a symlink (linked install) at: ${PLUGIN_LINK}"
  echo "Linked installs already share the framework source directly; nothing to sync in place."
  exit 0
fi

python3 - "${PROJECT_PATH}" "${FRAMEWORK_ROOT}" "${DRY_RUN}" "${FRAMEWORK_ROOT_SOURCE}" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import re
import stat
import subprocess
import sys

project_root = Path(sys.argv[1]).resolve()
framework_root = Path(sys.argv[2]).resolve()
dry_run = sys.argv[3] == "1"
framework_root_source = sys.argv[4]

plugin_src = framework_root / "plugins" / "codex-copilot"
gate_src = framework_root / "scripts" / "copilot-gate.sh"

FRONTMATTER_OWNER_RE = re.compile(r"^owner:\s*project\s*$", re.MULTILINE)


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


# managed_outputs fingerprints -- byte-for-byte reimplementations of
# claude-copilot's cc.core.ecosystem.project_locking.fingerprint_file_payload
# / fingerprint_symlink. Duplicated here rather than imported: codex-copilot
# is a standalone repo/product and must not take a runtime dependency on
# another repo's private Python package just to write a lock record it
# already knows the shape of. The two implementations are proven identical
# (independently verified against cc's real functions) and MUST stay that
# way, because cc's project_integration.py reader recomputes and compares
# this fingerprint -- it never trusts the value recorded here.
def _canonical_json(value) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")


def _fingerprint(value) -> str:
    return "sha256:" + hashlib.sha256(_canonical_json(value)).hexdigest()


def fingerprint_file_payload(payload: bytes, mode: int) -> str:
    return _fingerprint(["file", mode, hashlib.sha256(payload).hexdigest()])


def fingerprint_symlink(link_value: str) -> str:
    return _fingerprint(["symlink", link_value])


def relpaths(root: Path):
    for path in sorted(root.rglob("*")):
        if path.is_file():
            yield path.relative_to(framework_root).as_posix()


def has_project_owner_frontmatter(path: Path) -> bool:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False
    if not text.startswith("---"):
        return False
    end = text.find("\n---", 3)
    frontmatter = text[:end] if end != -1 else text
    return bool(FRONTMATTER_OWNER_RE.search(frontmatter))


canonical = list(relpaths(plugin_src))
canonical.append(gate_src.relative_to(framework_root).as_posix())

lock_path = project_root / "copilot.lock.json"
lock_data: dict = {"schema_version": "1.0", "components": []}
if lock_path.is_file():
    try:
        lock_data = json.loads(lock_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        lock_data = {"schema_version": "1.0", "components": []}

components = lock_data.get("components", [])
other_components = [c for c in components if c.get("component") != "codex"]
codex_component = next((c for c in components if c.get("component") == "codex"), None)
prior_files = {f.get("path"): f for f in (codex_component or {}).get("files", [])}

added, updated, unchanged, preserved, retired, orphaned_project = [], [], [], [], [], []
new_files_entries = []

for relpath in canonical:
    target = project_root / relpath
    source = framework_root / relpath
    source_bytes = source.read_bytes()
    source_sum = sha256_bytes(source_bytes)

    prior = prior_files.get(relpath)
    prior_ownership = prior.get("ownership") if prior else "framework"

    if not target.exists():
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source_bytes)
        added.append(relpath)
        new_files_entries.append({"path": relpath, "ownership": "framework", "checksum": source_sum})
        continue

    effective_ownership = "project" if (has_project_owner_frontmatter(target) or prior_ownership == "project") else "framework"

    if effective_ownership == "project":
        preserved.append(relpath)
        new_files_entries.append({"path": relpath, "ownership": "project", "checksum": sha256_bytes(target.read_bytes())})
        continue

    target_sum = sha256_bytes(target.read_bytes())
    if target_sum == source_sum:
        unchanged.append(relpath)
    else:
        if not dry_run:
            target.write_bytes(source_bytes)
        updated.append(relpath)
    new_files_entries.append({"path": relpath, "ownership": "framework", "checksum": source_sum})

canonical_set = set(canonical)
for relpath, prior in prior_files.items():
    if relpath in canonical_set:
        continue
    target = project_root / relpath
    if prior.get("ownership") == "project":
        if target.exists():
            orphaned_project.append(relpath)
        continue
    if target.exists():
        if not dry_run:
            target.unlink()
        retired.append(relpath)

# managed_outputs (schema: {"path", "kind", "fingerprint"} exactly -- cc's
# project_integration.py reader rejects any record missing "fingerprint" as
# an "invalid managed-output record"). Populated below as each managed
# output is actually resolved; a path is only ever recorded here once this
# run has made (or confirmed) it match its expected content -- never for a
# path this run left in an unknown/unexpected state.
managed_outputs_entries: list[dict[str, str]] = []

# Framework-managed skill bridge symlink: verify and repair, never left
# broken. The target is relative to the PROJECT's own plugin copy (not the
# framework source) so the link stays portable across machines/clones.
skills_link = project_root / ".claude" / "skills" / "codex-copilot"
project_plugin_skills = project_root / "plugins" / "codex-copilot" / "skills"
skills_target_expected = __import__("os").path.relpath(project_plugin_skills, skills_link.parent)
if skills_link.is_symlink():
    current = __import__("os").readlink(skills_link)
    symlink_status = "unchanged"
    if current != skills_target_expected:
        if not dry_run:
            skills_link.unlink()
            skills_link.symlink_to(skills_target_expected)
        symlink_status = "repaired"
elif skills_link.exists():
    symlink_status = "left alone (unexpected non-symlink at this path)"
else:
    if not dry_run:
        skills_link.parent.mkdir(parents=True, exist_ok=True)
        skills_link.symlink_to(skills_target_expected)
    symlink_status = "created"

if symlink_status != "left alone (unexpected non-symlink at this path)":
    managed_outputs_entries.append(
        {
            "path": ".claude/skills/codex-copilot",
            "kind": "internal-symlink",
            "fingerprint": fingerprint_symlink(skills_target_expected),
        }
    )

# .codex-copilot.json: field-level merge only. projectName/pluginPath are
# project-owned and are never overwritten; framework tracking fields are
# refreshed so the install metadata reflects what was actually synced.
codex_config_path = project_root / ".codex-copilot.json"
plugin_manifest = json.loads((plugin_src / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
framework_version = plugin_manifest.get("version", "unknown")

if codex_config_path.is_file():
    try:
        cfg = json.loads(codex_config_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        cfg = {}
    install_type = cfg.get("installType", "copy")
    codex_config_mode = stat.S_IMODE(codex_config_path.lstat().st_mode)
    if install_type == "link":
        config_status = "skipped (installType=link; plugin already synced via symlink)"
        codex_config_bytes = codex_config_path.read_bytes()
    else:
        commit = "unknown"
        try:
            commit = subprocess.run(
                ["git", "-C", str(framework_root), "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, check=True,
            ).stdout.strip()
        except (subprocess.CalledProcessError, OSError):
            pass
        cfg["frameworkVersion"] = framework_version
        cfg["frameworkCommit"] = commit
        cfg.setdefault("installType", "copy")
        cfg["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        cfg["updatedBy"] = f"codex-copilot {framework_version} update-project.sh"
        codex_config_bytes = (json.dumps(cfg, indent=2) + "\n").encode("utf-8")
        if not dry_run:
            codex_config_path.write_bytes(codex_config_bytes)
        config_status = "refreshed tracking fields (projectName/pluginPath preserved)"
    managed_outputs_entries.append(
        {
            "path": ".codex-copilot.json",
            "kind": "merged-json",
            "fingerprint": fingerprint_file_payload(codex_config_bytes, codex_config_mode),
        }
    )
else:
    config_status = "absent (project not fully set up; leaving as-is)"

new_codex_component = {
    "component": "codex",
    "release_tag": f"v{framework_version}",
    "version": framework_version,
    "files": sorted(new_files_entries, key=lambda f: f["path"]),
    "managed_outputs": sorted(managed_outputs_entries, key=lambda o: (o["path"], o["kind"])),
}
lock_data["schema_version"] = lock_data.get("schema_version", "1.0")
lock_data["components"] = other_components + [new_codex_component]
if not dry_run:
    lock_path.write_text(json.dumps(lock_data, indent=2) + "\n", encoding="utf-8")


def section(title, items):
    print(f"{title}: {len(items)}")
    for item in items:
        print(f"  - {item}")


print(f"{'[dry-run] ' if dry_run else ''}codex-copilot update-project report")
print(f"Project: {project_root}")
print(f"Framework root: {framework_root}")
print(f"Framework root source: {framework_root_source}")
print(f"Framework version: {framework_version}")
print()
section("Updated (framework-owned, content differed from source)", updated)
section("Added (missing framework files installed)", added)
print(f"Unchanged (already matched source): {len(unchanged)}")
section("Preserved (ownership: project -- left untouched)", preserved)
section("Retired (removed; no longer part of the framework roster)", retired)
section("Orphaned project files (path left the roster, ownership: project -- left in place, review manually)", orphaned_project)
print(f"Skill symlink (.claude/skills/codex-copilot): {symlink_status}")
print(f".codex-copilot.json: {config_status}")
print(f"copilot.lock.json: {'would be written' if dry_run else 'written'} ({len(new_files_entries)} codex file entries tracked)")
print()
changed = bool(updated or added or retired or symlink_status not in ("unchanged",))
if dry_run:
    print("Result: changes previewed (dry-run, nothing written)" if changed else "Result: no changes needed (dry-run)")
else:
    print("Result: changes applied" if changed else "Result: no changes needed (already up to date)")
PY
