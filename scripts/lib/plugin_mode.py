"""Shared executable-bit handling for plugin sync, used by both
setup-project.sh (fresh install, via a normalization pass after `cp -R`)
and update-project.sh (refresh, inline inside its sync_tree() comparison).
One implementation, imported by both -- not forked per script.

Only the executable bit is ever propagated from a source file, never the
full source mode (setuid, group-write, etc.): deterministic across
machines/umasks, and matches what setup-project.sh has always done by hand
via `chmod +x` on the QA gate.
"""

import stat
from pathlib import Path


def desired_mode(source: Path) -> int:
    source_mode = stat.S_IMODE(source.stat().st_mode)
    return 0o755 if (source_mode & 0o111) else 0o644


def normalize_tree_modes(source_root: Path, dest_root: Path) -> list:
    """Walk every file under dest_root that has a same-relpath counterpart
    under source_root and chmod it to that source file's desired_mode().

    Used right after a fresh recursive copy (setup-project.sh's `cp -R`)
    so mode correctness does not depend on `cp`'s umask-sensitive
    preservation behavior. update-project.sh does not call this directly:
    its sync_tree() already visits every canonical file itself and applies
    desired_mode() as part of that same pass.

    Returns the sorted list of relpaths whose mode was changed (empty if
    the copy already landed with correct modes).
    """
    changed = []
    for path in sorted(dest_root.rglob("*")):
        if not path.is_file():
            continue
        relpath = path.relative_to(dest_root).as_posix()
        source = source_root / relpath
        if not source.is_file():
            continue
        mode = desired_mode(source)
        if stat.S_IMODE(path.lstat().st_mode) != mode:
            path.chmod(mode)
            changed.append(relpath)
    return sorted(changed)
