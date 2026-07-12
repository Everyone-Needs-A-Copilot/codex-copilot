#!/usr/bin/env bash

set -euo pipefail

python3 tests/test_mirror_parity.py
bash scripts/check-versions.sh
python3 scripts/check-upstream-parity.py
python3 scripts/check-upstream-parity.py --content
python3 scripts/generate-routing.py --check
bash scripts/run-agent-evals.sh
python3 scripts/orchestrate-validate.py --json <<'JSON' >/dev/null
{
  "streams": [
    {
      "streamId": "Stream-A",
      "files": ["src/foundation.py"],
      "streamDependencies": []
    },
    {
      "streamId": "Stream-B",
      "files": ["src/feature.py"],
      "streamDependencies": ["Stream-A"]
    }
  ]
}
JSON

echo "Smoke tests passed"
