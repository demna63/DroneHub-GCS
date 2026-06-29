#!/usr/bin/env python3
"""Detect drift between custom QML sources and qmlcache sync targets."""
from __future__ import annotations

import difflib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CMAKE = ROOT / "custom/CMakeLists.txt"
QGC = ROOT / "qgroundcontrol"


def parse_sync_pairs(cmake_text: str) -> list[tuple[Path, Path]]:
    src_re = re.compile(
        r'set\(DRONEHUB_(\w+)_SRC\s+"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]+)"\)'
    )
    dst_re = re.compile(
        r'set\(DRONEHUB_(\w+)_DST\s+"\$\{CMAKE_SOURCE_DIR\}/([^"]+)"\)'
    )
    srcs = {m.group(1): m.group(2) for m in src_re.finditer(cmake_text)}
    dsts = {m.group(1): m.group(2) for m in dst_re.finditer(cmake_text)}
    pairs: list[tuple[Path, Path]] = []
    for key, rel_src in sorted(srcs.items()):
        rel_dst = dsts.get(key)
        if not rel_dst:
            continue
        pairs.append((ROOT / "custom" / rel_src, QGC / rel_dst))
    return pairs


def main() -> int:
    if not CMAKE.is_file():
        print(f"ERROR: missing {CMAKE}", file=sys.stderr)
        return 1

    pairs = parse_sync_pairs(CMAKE.read_text(encoding="utf-8"))
    if not pairs:
        print("ERROR: no DRONEHUB_*_SRC/DST pairs found in custom/CMakeLists.txt", file=sys.stderr)
        return 1

    missing_src: list[str] = []
    missing_dst: list[str] = []
    drifted: list[str] = []

    for src, dst in pairs:
        rel = src.relative_to(ROOT)
        if not src.is_file():
            missing_src.append(str(rel))
            continue
        if not QGC.is_dir():
            print(f"SKIP: qgroundcontrol/ not present — only checked {len(pairs)} source paths")
            return 0
        if not dst.is_file():
            missing_dst.append(str(dst.relative_to(QGC)))
            continue
        if src.read_bytes() != dst.read_bytes():
            diff = difflib.unified_diff(
                src.read_text(encoding="utf-8").splitlines(),
                dst.read_text(encoding="utf-8").splitlines(),
                fromfile=str(rel),
                tofile=str(dst.relative_to(QGC)),
                lineterm="",
            )
            preview = "\n".join(list(diff)[:12])
            drifted.append(f"{rel} ↔ {dst.relative_to(QGC)}\n{preview}")

    errors = False
    if missing_src:
        errors = True
        print("Missing custom sources:", file=sys.stderr)
        for p in missing_src:
            print(f"  - {p}", file=sys.stderr)

    if missing_dst:
        errors = True
        print("Missing qmlcache sync targets (run cmake build DroneHubSyncFlyViewLayer):", file=sys.stderr)
        for p in missing_dst:
            print(f"  - {p}", file=sys.stderr)

    if drifted:
        errors = True
        print("QML sync drift detected:", file=sys.stderr)
        for block in drifted:
            print(block, file=sys.stderr)
            print("---", file=sys.stderr)

    if errors:
        return 1

    print(f"QML override drift check OK ({len(pairs)} sync pairs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
