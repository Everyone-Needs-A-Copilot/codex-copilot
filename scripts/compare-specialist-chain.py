#!/usr/bin/env python3
"""Compare evidence-backed scorecards for generalist and specialist-chain runs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def load_scorecard(path: Path) -> dict:
    data = json.loads(path.read_text())
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError(f"{path}: cases must be a non-empty list")
    indexed = {}
    for case in cases:
        case_id = str(case.get("id") or "")
        criteria = case.get("criteria")
        if not case_id or not isinstance(criteria, dict) or not criteria:
            raise ValueError(f"{path}: each case needs id and criteria")
        if case_id in indexed:
            raise ValueError(f"{path}: duplicate case id {case_id}")
        for name, result in criteria.items():
            score = result.get("score") if isinstance(result, dict) else None
            evidence = result.get("evidence") if isinstance(result, dict) else None
            if not isinstance(score, (int, float)) or not 0 <= score <= 1:
                raise ValueError(f"{path}: {case_id}.{name} score must be between 0 and 1")
            if not isinstance(evidence, str) or not evidence.strip():
                raise ValueError(f"{path}: {case_id}.{name} needs evidence")
        indexed[case_id] = criteria
    return {"variant": data.get("variant", path.stem), "cases": indexed}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generalist", required=True, type=Path)
    parser.add_argument("--specialist", required=True, type=Path)
    parser.add_argument("--min-delta", type=float, default=0.05)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    generalist = load_scorecard(args.generalist)
    specialist = load_scorecard(args.specialist)
    if set(generalist["cases"]) != set(specialist["cases"]):
        raise SystemExit("scorecards must contain identical case ids")
    rows = []
    for case_id in sorted(generalist["cases"]):
        left = generalist["cases"][case_id]
        right = specialist["cases"][case_id]
        if set(left) != set(right):
            raise SystemExit(f"{case_id}: scorecards must contain identical criteria")
        for criterion in sorted(left):
            rows.append((float(left[criterion]["score"]), float(right[criterion]["score"])))
    generalist_mean = sum(left for left, _ in rows) / len(rows)
    specialist_mean = sum(right for _, right in rows) / len(rows)
    delta = specialist_mean - generalist_mean
    verdict = "specialist-chain" if delta >= args.min_delta else "generalist" if delta <= -args.min_delta else "inconclusive"
    result = {"generalist_mean": round(generalist_mean, 4), "specialist_mean": round(specialist_mean, 4), "delta": round(delta, 4), "min_delta": args.min_delta, "verdict": verdict, "observations": len(rows)}
    print(json.dumps(result, indent=2) if args.json else f"generalist={generalist_mean:.3f} specialist={specialist_mean:.3f} delta={delta:+.3f} verdict={verdict}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
