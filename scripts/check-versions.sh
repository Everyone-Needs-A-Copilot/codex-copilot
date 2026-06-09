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

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)
print(f"Version check passed for codex-copilot {expected}")
PY
