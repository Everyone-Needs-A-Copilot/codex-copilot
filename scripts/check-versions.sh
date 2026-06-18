#!/usr/bin/env bash

set -euo pipefail

python3 - <<'PY'
import json
from pathlib import Path

root = Path.cwd()
version = json.loads((root / "VERSION.json").read_text())
baseline = json.loads((root / "parity/claude-baseline.json").read_text())
plugin = json.loads((root / "plugins/codex-copilot/.codex-plugin/plugin.json").read_text())
catalog = json.loads((root / "plugins/codex-copilot/agent-catalog.json").read_text())
catalog_schema = json.loads((root / "plugins/codex-copilot/agent-catalog.schema.json").read_text())

expected = version["version"]
errors = []
if plugin["version"] != expected:
    errors.append(f"plugin version {plugin['version']} != VERSION.json {expected}")
if catalog["version"] != expected:
    errors.append(f"catalog version {catalog['version']} != VERSION.json {expected}")
if version["mirrors"]["frameworkVersion"] != baseline["baseline"]["frameworkVersion"]:
    errors.append("mirrored Claude framework version does not match baseline")
if version["components"]["cc"]["requiredVersion"] != baseline["components"]["cc"]["version"]:
    errors.append("cc required version does not match baseline")
if version["components"]["tc"]["requiredVersion"] != baseline["components"]["tc"]["version"]:
    errors.append("tc required version does not match baseline")
if "schemaVersion" not in catalog:
    errors.append("agent catalog missing schemaVersion")
if catalog_schema.get("title") != "Codex Copilot Agent Catalog":
    errors.append("agent catalog schema has unexpected title")
if catalog.get("designChain") != ["sd", "uxd", "uids", "uid", "ta", "me", "qa"]:
    errors.append("agent catalog designChain does not match design-led contract")

for pack in (root / "packs").iterdir():
    if not pack.is_dir() or not (pack / "skills").exists():
        continue
    manifest_path = pack / "pack.json"
    if not manifest_path.exists():
        errors.append(f"pack {pack.name} is missing pack.json")
        continue
    manifest = json.loads(manifest_path.read_text())
    if manifest.get("name") != pack.name:
        errors.append(f"pack {pack.name} manifest name mismatch")
    for specialist in manifest.get("specialists", []):
        if not (pack / "skills" / specialist / "SKILL.md").exists():
            errors.append(f"pack {pack.name} references missing skill {specialist}")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)
print(f"Version check passed for codex-copilot {expected}")
PY
