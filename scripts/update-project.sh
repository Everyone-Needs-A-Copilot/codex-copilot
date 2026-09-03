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
  --org-plugin PATH       Install/refresh an additional organization-owned
                           plugin from PATH, alongside the base plugin
                           (opt-in; never replaces the base plugin)
  --no-org-plugin         Do not install, refresh, or auto-detect an
                           organization plugin this run
  --dry-run               Report what would change without writing anything
  --help                  Show this help

Organization plugin resolution (when neither --org-plugin nor
--no-org-plugin is given): a previously recorded orgPluginSourcePath in the
project's .codex-copilot.json is used first, so a plain re-run keeps an
already-installed organization plugin updated without repeating the flag.
Failing that, a sibling repo next to the framework root --
<framework-root-parent>/codex-copilot-internal/plugins/codex-copilot-internal
-- is auto-detected and used only when it exists. If none of that resolves
anything, no organization plugin is touched: a project with no flag, no
recorded key, and no sibling repo present is refreshed identically to how
this script behaved before organization-plugin support existed. The
organization plugin installs to plugins/<name>, where <name> comes from its
own .codex-plugin/plugin.json manifest, and is synced with the same
content-hash comparison and ownership: project preservation as the base
plugin.

Refreshes an EXISTING codex-copilot install in place. Every framework-owned
file under plugins/codex-copilot/ plus scripts/copilot-gate.sh is compared BY
CONTENT (sha256, not by declared version) against the framework source and repaired when it
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
second run. Never destructive outside the discovered locked paths -- AGENTS.md,
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
ORG_PLUGIN_ARG=""
NO_ORG_PLUGIN=0

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
    --org-plugin)
      ORG_PLUGIN_ARG="${2:-}"
      shift 2
      ;;
    --no-org-plugin)
      NO_ORG_PLUGIN=1
      shift
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

if [[ -n "${ORG_PLUGIN_ARG}" && "${NO_ORG_PLUGIN}" -eq 1 ]]; then
  echo "--org-plugin and --no-org-plugin are mutually exclusive" >&2
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

# shellcheck source=lib/resolve-org-plugin.sh
source "${SCRIPT_DIR}/lib/resolve-org-plugin.sh"
codex_resolve_org_plugin_source

if [[ -L "${PLUGIN_LINK}" ]]; then
  echo "plugins/codex-copilot is a symlink (linked install) at: ${PLUGIN_LINK}"
  echo "Linked installs already share the framework source directly; nothing to sync in place."
  if [[ -n "${ORG_PLUGIN_SOURCE}" ]]; then
    echo "Note: organization plugin sync is not yet supported alongside a linked base install; skipping (${ORG_PLUGIN_SOURCE_DESC})."
  fi
  exit 0
fi

python3 - "${PROJECT_PATH}" "${FRAMEWORK_ROOT}" "${DRY_RUN}" "${FRAMEWORK_ROOT_SOURCE}" "${ORG_PLUGIN_SOURCE}" "${ORG_PLUGIN_SOURCE_DESC}" "${SCRIPT_DIR}" <<'PY'
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
org_plugin_source_arg = sys.argv[5]
org_plugin_source_desc = sys.argv[6]
script_dir = Path(sys.argv[7]).resolve()

sys.path.insert(0, str(script_dir / "lib"))
from plugin_mode import desired_mode  # noqa: E402 -- shared with setup-project.sh, not forked

plugin_src = framework_root / "plugins" / "codex-copilot"
gate_src = framework_root / "scripts" / "copilot-gate.sh"

org_plugin_source = Path(org_plugin_source_arg).resolve() if org_plugin_source_arg else None
org_plugin_name = None
org_plugin_manifest: dict = {}
if org_plugin_source is not None:
    org_manifest_path = org_plugin_source / ".codex-plugin" / "plugin.json"
    if not org_manifest_path.is_file():
        print(f"ERROR: org plugin source missing manifest: {org_manifest_path}", file=sys.stderr)
        sys.exit(1)
    org_plugin_manifest = json.loads(org_manifest_path.read_text(encoding="utf-8"))
    org_plugin_name = org_plugin_manifest.get("name") or org_plugin_source.name

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


def relpaths_under(root: Path, base: Path):
    for path in sorted(root.rglob("*")):
        if path.is_file():
            yield path.relative_to(base).as_posix()


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


canonical = list(relpaths_under(plugin_src, framework_root))
canonical.append(gate_src.relative_to(framework_root).as_posix())

org_canonical = list(relpaths_under(org_plugin_source, org_plugin_source)) if org_plugin_source is not None else []

ORG_LOCK_COMPONENT = "codex-org"

lock_path = project_root / "copilot.lock.json"
lock_data: dict = {"schema_version": "1.0", "components": []}
if lock_path.is_file():
    try:
        lock_data = json.loads(lock_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        lock_data = {"schema_version": "1.0", "components": []}

components = lock_data.get("components", [])
codex_component = next((c for c in components if c.get("component") == "codex"), None)
prior_files = {f.get("path"): f for f in (codex_component or {}).get("files", [])}
prior_org_component = next((c for c in components if c.get("component") == ORG_LOCK_COMPONENT), None)
prior_org_files = {f.get("path"): f for f in (prior_org_component or {}).get("files", [])}
other_components = [c for c in components if c.get("component") not in ("codex", ORG_LOCK_COMPONENT)]


# desired_mode() is imported from scripts/lib/plugin_mode.py above, shared
# with setup-project.sh's post-copy mode normalization rather than
# reimplemented here.


# Shared sync engine: compares every canonical file BY CONTENT (sha256, not
# declared version) AND BY EXECUTABLE BIT between source_root and dest_root,
# repairs either kind of drift, installs anything missing (with the correct
# mode from the start), retires anything that left the roster, and never
# touches a path whose effective ownership is "project" -- content or mode.
# Used for both the base plugin (source_root=framework_root,
# dest_root=project_root) and an organization plugin (source_root/dest_root
# scoped to that plugin's own tree) so there is exactly one sync
# implementation, not two.
#
# A mode-only mismatch (content identical, executable bit differs) is
# tracked and reported separately from "updated" rather than folded into
# it: content drift means the file says something different and is worth
# scrutinizing (it may carry unreviewed bytes); a mode-only mismatch is
# almost always a mechanical artifact of how the tree was moved (a git
# checkout with core.fileMode off, a zip/tar that drops exec bits) and
# should read as "the copy was mechanically repaired," not "the file
# changed." Both still count toward "changes were made" for the run's
# overall result -- neither is silently absorbed into "unchanged".
def sync_tree(source_root: Path, dest_root: Path, canonical_paths: list, prior: dict, dry_run: bool) -> dict:
    added, updated, unchanged, preserved, retired, orphaned_project = [], [], [], [], [], []
    mode_repaired = []
    new_entries = []

    for relpath in canonical_paths:
        target = dest_root / relpath
        source = source_root / relpath
        source_bytes = source.read_bytes()
        source_sum = sha256_bytes(source_bytes)
        target_mode = desired_mode(source)

        prior_entry = prior.get(relpath)
        prior_ownership = prior_entry.get("ownership") if prior_entry else "framework"

        if not target.exists():
            if not dry_run:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source_bytes)
                target.chmod(target_mode)
            added.append(relpath)
            new_entries.append({"path": relpath, "ownership": "framework", "checksum": source_sum})
            continue

        effective_ownership = "project" if (has_project_owner_frontmatter(target) or prior_ownership == "project") else "framework"

        if effective_ownership == "project":
            preserved.append(relpath)
            new_entries.append({"path": relpath, "ownership": "project", "checksum": sha256_bytes(target.read_bytes())})
            continue

        target_sum = sha256_bytes(target.read_bytes())
        content_changed = target_sum != source_sum
        mode_changed = stat.S_IMODE(target.lstat().st_mode) != target_mode

        if content_changed:
            if not dry_run:
                target.write_bytes(source_bytes)
                target.chmod(target_mode)
            updated.append(relpath)
        elif mode_changed:
            if not dry_run:
                target.chmod(target_mode)
            mode_repaired.append(relpath)
        else:
            unchanged.append(relpath)
        new_entries.append({"path": relpath, "ownership": "framework", "checksum": source_sum})

    canonical_set = set(canonical_paths)
    for relpath, prior_entry in prior.items():
        if relpath in canonical_set:
            continue
        target = dest_root / relpath
        if prior_entry.get("ownership") == "project":
            if target.exists():
                orphaned_project.append(relpath)
            continue
        if target.exists():
            if not dry_run:
                target.unlink()
            retired.append(relpath)

    return {
        "added": added, "updated": updated, "unchanged": unchanged,
        "preserved": preserved, "retired": retired, "orphaned_project": orphaned_project,
        "mode_repaired": mode_repaired,
        "new_files_entries": new_entries,
    }


base_sync = sync_tree(framework_root, project_root, canonical, prior_files, dry_run)
added = base_sync["added"]
updated = base_sync["updated"]
unchanged = base_sync["unchanged"]
preserved = base_sync["preserved"]
retired = base_sync["retired"]
orphaned_project = base_sync["orphaned_project"]
mode_repaired = base_sync["mode_repaired"]
new_files_entries = base_sync["new_files_entries"]

org_sync = None
org_dest_root = project_root / "plugins" / (org_plugin_name or "")
if org_plugin_source is not None:
    org_sync = sync_tree(org_plugin_source, org_dest_root, org_canonical, prior_org_files, dry_run)

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

# Organization plugin skill bridge symlink -- same treatment as the base
# plugin's, scoped to the org plugin's own name and skills/ directory (when
# it has one). Skipped entirely when no org plugin resolved this run, which
# leaves any previously-installed bridge untouched on disk.
org_managed_outputs_entries: list = []
org_symlink_status = None
if org_plugin_source is not None:
    org_skills_source = org_plugin_source / "skills"
    if org_skills_source.is_dir():
        org_skills_link = project_root / ".claude" / "skills" / org_plugin_name
        org_project_plugin_skills = org_dest_root / "skills"
        org_skills_target_expected = __import__("os").path.relpath(org_project_plugin_skills, org_skills_link.parent)
        if org_skills_link.is_symlink():
            current = __import__("os").readlink(org_skills_link)
            org_symlink_status = "unchanged"
            if current != org_skills_target_expected:
                if not dry_run:
                    org_skills_link.unlink()
                    org_skills_link.symlink_to(org_skills_target_expected)
                org_symlink_status = "repaired"
        elif org_skills_link.exists():
            org_symlink_status = "left alone (unexpected non-symlink at this path)"
        else:
            if not dry_run:
                org_skills_link.parent.mkdir(parents=True, exist_ok=True)
                org_skills_link.symlink_to(org_skills_target_expected)
            org_symlink_status = "created"
        if org_symlink_status != "left alone (unexpected non-symlink at this path)":
            org_managed_outputs_entries.append(
                {
                    "path": f".claude/skills/{org_plugin_name}",
                    "kind": "internal-symlink",
                    "fingerprint": fingerprint_symlink(org_skills_target_expected),
                }
            )
    else:
        org_symlink_status = "skipped (org plugin has no skills/ directory)"

# .codex-copilot.json: field-level merge only. projectName/pluginPath are
# project-owned and are never overwritten; framework tracking fields (and,
# when an org plugin resolved this run, orgPlugin* tracking fields) are
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

    if org_plugin_source is not None:
        cfg["orgPluginName"] = org_plugin_name
        cfg["orgPluginPath"] = f"./plugins/{org_plugin_name}"
        cfg["orgPluginSourcePath"] = str(org_plugin_source)
        cfg["orgPluginInstallType"] = "copy"
        cfg["orgPluginVersion"] = org_plugin_manifest.get("version", "unknown")

    if install_type == "link" and org_plugin_source is None:
        config_status = "skipped (installType=link; plugin already synced via symlink)"
        codex_config_bytes = codex_config_path.read_bytes()
    else:
        status_bits = []
        if install_type != "link":
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
            status_bits.append("refreshed tracking fields (projectName/pluginPath preserved)")
        else:
            status_bits.append("base plugin fields skipped (installType=link)")
        if org_plugin_source is not None:
            status_bits.append(f"org plugin fields refreshed ({org_plugin_name})")
        codex_config_bytes = (json.dumps(cfg, indent=2) + "\n").encode("utf-8")
        if not dry_run:
            codex_config_path.write_bytes(codex_config_bytes)
        config_status = "; ".join(status_bits)
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

components_out = list(other_components) + [new_codex_component]
if org_sync is not None:
    new_org_component = {
        "component": ORG_LOCK_COMPONENT,
        "plugin_name": org_plugin_name,
        "version": org_plugin_manifest.get("version", "unknown"),
        "files": sorted(org_sync["new_files_entries"], key=lambda f: f["path"]),
        "managed_outputs": sorted(org_managed_outputs_entries, key=lambda o: (o["path"], o["kind"])),
    }
    components_out.append(new_org_component)
elif prior_org_component is not None:
    # No org plugin resolved this run (suppressed, or nothing to resolve) --
    # leave a previously-tracked org component exactly as it was rather than
    # dropping it from the lock file.
    components_out.append(prior_org_component)

lock_data["schema_version"] = lock_data.get("schema_version", "1.0")
lock_data["components"] = components_out
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
section("Mode repaired (content matched, executable bit corrected)", mode_repaired)
print(f"Unchanged (already matched source, content and mode): {len(unchanged)}")
section("Preserved (ownership: project -- left untouched)", preserved)
section("Retired (removed; no longer part of the framework roster)", retired)
section("Orphaned project files (path left the roster, ownership: project -- left in place, review manually)", orphaned_project)
print(f"Skill symlink (.claude/skills/codex-copilot): {symlink_status}")
print(f".codex-copilot.json: {config_status}")
print(f"copilot.lock.json: {'would be written' if dry_run else 'written'} ({len(new_files_entries)} codex file entries tracked)")
print()
print(f"Org plugin: {org_plugin_source_desc}")
org_changed = False
if org_sync is not None:
    print(f"Org plugin name: {org_plugin_name}")
    print(f"Org plugin version: {org_plugin_manifest.get('version', 'unknown')}")
    section("Org plugin -- Updated (content differed from source)", org_sync["updated"])
    section("Org plugin -- Added (missing files installed)", org_sync["added"])
    section("Org plugin -- Mode repaired (content matched, executable bit corrected)", org_sync["mode_repaired"])
    print(f"Org plugin -- Unchanged (already matched source, content and mode): {len(org_sync['unchanged'])}")
    section("Org plugin -- Preserved (ownership: project -- left untouched)", org_sync["preserved"])
    section("Org plugin -- Retired (removed; no longer part of the org plugin roster)", org_sync["retired"])
    section("Org plugin -- Orphaned project files", org_sync["orphaned_project"])
    print(f"Org plugin skill symlink (.claude/skills/{org_plugin_name}): {org_symlink_status}")
    org_changed = bool(
        org_sync["updated"]
        or org_sync["added"]
        or org_sync["retired"]
        or org_sync["mode_repaired"]
        or org_symlink_status not in (None, "unchanged", "skipped (org plugin has no skills/ directory)")
    )
print()
changed = bool(updated or added or retired or mode_repaired or symlink_status not in ("unchanged",)) or org_changed
if dry_run:
    print("Result: changes previewed (dry-run, nothing written)" if changed else "Result: no changes needed (dry-run)")
else:
    print("Result: changes applied" if changed else "Result: no changes needed (already up to date)")
PY
