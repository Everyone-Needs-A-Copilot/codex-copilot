#!/usr/bin/env bash

set -euo pipefail

python3 - <<'PY'
import math
import os
import signal
import subprocess
import sys
import time

name = 'python-test-discovery'
try:
    cap = float(os.environ.get('COPILOT_SMOKE_PYTHON_TIMEOUT', '180'))
    if not math.isfinite(cap) or not 0 < cap <= 900:
        raise ValueError()
except ValueError:
    print(f'[{name}] invalid cap: require 0 < seconds <= 900', flush=True)
    raise SystemExit(2)
discovery = '''import sys, unittest
suite = unittest.defaultTestLoader.discover('tests', pattern='test_*.py')
if not suite.countTestCases():
    print('No Python tests discovered; verification is incomplete', file=sys.stderr)
    raise SystemExit(2)
result = unittest.TextTestRunner(verbosity=2).run(suite)
raise SystemExit(0 if result.wasSuccessful() else 1)
'''
command = [sys.executable, '-c', discovery]
start = time.monotonic()
print(f'[{name}] start cap={cap:g}s command=unittest discovery tests/test_*.py', flush=True)
child = subprocess.Popen(command, start_new_session=True)


def stop_owned_group():
    # Reap a terminated leader before the next signal: on macOS, killpg against
    # its otherwise-empty zombie group can return EPERM instead of ESRCH.
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(child.pid, sig)
        except ProcessLookupError:
            return
        if sig == signal.SIGTERM:
            try:
                child.wait(timeout=0.1)
            except subprocess.TimeoutExpired:
                pass
    child.wait()


def interrupted(signum, frame):
    raise KeyboardInterrupt(signum)


signal.signal(signal.SIGTERM, interrupted)
try:
    while True:
        remaining = cap - (time.monotonic() - start)
        if remaining <= 0:
            stop_owned_group()
            print(f'[{name}] incomplete timeout elapsed={time.monotonic() - start:.2f}s', flush=True)
            raise SystemExit(124)
        try:
            code = child.wait(timeout=min(30, remaining))
            break
        except subprocess.TimeoutExpired:
            if time.monotonic() - start < cap:
                print(f'[{name}] running elapsed={time.monotonic() - start:.2f}s', flush=True)
except KeyboardInterrupt as exc:
    stop_owned_group()
    code = 143 if exc.args == (signal.SIGTERM,) else 130
    print(f'[{name}] incomplete interrupted elapsed={time.monotonic() - start:.2f}s', flush=True)
    raise SystemExit(code)
code = code if code >= 0 else 128 - code
print(f'[{name}] exit={code} elapsed={time.monotonic() - start:.2f}s', flush=True)
raise SystemExit(code)
PY
bash scripts/verify-codex-hooks.sh
bash scripts/check-versions.sh
python3 scripts/check-upstream-parity.py
python3 scripts/check-upstream-parity.py --content
python3 scripts/generate-routing.py --check
bash scripts/run-agent-evals.sh
bash scripts/verify-update-project.sh
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
