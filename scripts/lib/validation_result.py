"""Structured validation results for Codex Copilot scripts.

Use this shape when a script needs to report failable checks with evidence.
It intentionally mirrors Claude Copilot's 5.10 validation-result contract while
staying independent of Claude hook paths.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Literal


Status = Literal["pass", "fail", "warn"]
Verdict = Literal["pass", "fail", "warn"]

_SEVERITY = {"pass": 0, "warn": 1, "fail": 2}


@dataclass
class CheckResult:
    check: str
    status: Status
    message: str = ""
    expected: str | None = None
    actual: str | None = None
    artifact: str | None = None

    def to_dict(self) -> dict[str, str]:
        data = {"check": self.check, "status": self.status}
        if self.message:
            data["message"] = self.message
        if self.expected is not None:
            data["expected"] = self.expected
        if self.actual is not None:
            data["actual"] = self.actual
        if self.artifact is not None:
            data["artifact"] = self.artifact
        return data


@dataclass
class ValidationReport:
    checks: list[CheckResult] = field(default_factory=list)
    context: str | None = None

    @property
    def verdict(self) -> Verdict:
        if not self.checks:
            return "pass"
        severity = max(_SEVERITY.get(check.status, 0) for check in self.checks)
        if severity >= 2:
            return "fail"
        if severity >= 1:
            return "warn"
        return "pass"

    def to_dict(self) -> dict:
        data = {
            "verdict": self.verdict,
            "checks": [check.to_dict() for check in self.checks],
        }
        if self.context is not None:
            data["context"] = self.context
        return data

    def to_json(self, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent)

    def to_shell_json(self) -> str:
        return json.dumps(self.to_dict(), separators=(",", ":"))

    def passed(self) -> bool:
        return self.verdict == "pass"

    def failed(self) -> bool:
        return self.verdict == "fail"


def passed(check: str, message: str = "", artifact: str | None = None) -> CheckResult:
    return CheckResult(check=check, status="pass", message=message, artifact=artifact)


def warned(
    check: str,
    message: str = "",
    expected: str | None = None,
    actual: str | None = None,
    artifact: str | None = None,
) -> CheckResult:
    return CheckResult(
        check=check,
        status="warn",
        message=message,
        expected=expected,
        actual=actual,
        artifact=artifact,
    )


def failed(
    check: str,
    message: str = "",
    expected: str | None = None,
    actual: str | None = None,
    artifact: str | None = None,
) -> CheckResult:
    return CheckResult(
        check=check,
        status="fail",
        message=message,
        expected=expected,
        actual=actual,
        artifact=artifact,
    )


if __name__ == "__main__":
    report = ValidationReport(
        checks=[
            passed("import", "validation_result.py imports cleanly"),
            passed("shape", "ValidationReport emits JSON"),
        ],
        context="smoke-test",
    )
    print(report.to_shell_json())
