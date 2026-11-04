#!/usr/bin/env python3
"""Deprecated stream-plan adapter to shared tc validation.

Legacy streamId/files/streamDependencies are accepted. Shared validation owns
cycle detected and file ownership overlap diagnostics; no local glob algorithm.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts/lib'))
from validation_result import ValidationReport, failed, passed

REQUIRED_FIELDS = {'streamId', 'files', 'streamDependencies'}

def load_payload(path: str | None) -> Any:
    return json.loads(Path(path).read_text() if path else sys.stdin.read())

def normalize(payload: Any) -> dict:
    if isinstance(payload, dict) and 'schemaVersion' in payload:
        return payload
    streams = payload.get('streams') if isinstance(payload, dict) else payload
    if not isinstance(streams, list):
        raise ValueError('stream payload must be a list or an object with streams[]')
    normalized = []
    for index, stream in enumerate(streams):
        if not isinstance(stream, dict) or REQUIRED_FIELDS - stream.keys():
            raise ValueError(f'stream {index} requires streamId, files and streamDependencies')
        if not all(isinstance(stream[key], list) for key in ['files','streamDependencies']):
            raise ValueError(f'stream {index}: files and streamDependencies must be lists')
        paths = stream['files'] + stream.get('streamPaths', [])
        normalized.append({'id':stream['streamId'],'task':index+1,'role':'me','kind':'code','paths':paths,'readOnly':False,'dependsOn':[{'stream':dep,'event':'built','reason':'Declared legacy stream input dependency'} for dep in stream['streamDependencies']],'resource':'light','worktree':str(Path.cwd().resolve()/'.worktrees'/'legacy-validation'/str(stream['streamId'])),'branch':'legacy-validation/'+str(stream['streamId'])})
    return {'schemaVersion':1,'id':'legacy-validation','task':1,'runtime':'codex','root':str(Path.cwd().resolve()),'capacity':max(1,len(normalized)),'resourceLimits':{'light':max(1,len(normalized))},'streams':normalized}

def validate(payload: Any) -> list[str]:
    try:
        from tc.services.cycles import validate_plan
        validate_plan(normalize(payload))
        return []
    except ImportError:
        return ['Shared tc cycle validation is unavailable; update shared tooling before parallel dispatch']
    except Exception as exc:
        return [str(exc)]

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', nargs='?', help='JSON plan path; reads stdin when omitted')
    parser.add_argument('--json', action='store_true')
    args=parser.parse_args()
    try:
        payload=load_payload(args.path)
        errors=validate(payload)
    except Exception as exc:
        errors=[str(exc)]
    checks=[failed('stream-validation',error,artifact=args.path or 'stdin') for error in errors] or [passed('stream-validation','Shared cycle validation passed',artifact=args.path or 'stdin')]
    report=ValidationReport(checks=checks,context='orchestrate-validate')
    if args.json:
        print(json.dumps({'valid':not errors,'errors':errors,'report':report.to_dict()},indent=2))
    else:
        print('\n'.join(errors) if errors else 'Shared cycle validation passed')
    return 1 if errors else 0

if __name__ == '__main__':
    raise SystemExit(main())
