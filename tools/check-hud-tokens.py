#!/usr/bin/env python3
"""Verify Theme.qml HUD tokens match FlyViewCustomLayer inline _t block."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THEME = ROOT / "custom/res/Custom/Theme.qml"
LAYER = ROOT / "custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml"

# Documented in .cursor/rules/flyview-hud.mdc — must stay in sync.
REQUIRED_KEYS = (
    "hudMetricCellWidthEm",
    "hudMetricColumnGapUnits",
    "hudCompactWidthPadUnits",
    "hudExpandedMaxWidthEm",
    "hudMetricLabelMaxLines",
    "hudMetricLabelLineHeight",
    "instrumentSizeCompact",
    "instrumentSizeExpanded",
    "fontCaption",
)

# Shared palette/spacing tokens — warn on drift (some font sizes may differ by design).
SHARED_KEYS = (
    "brandPrimary",
    "telemetryAccent",
    "hudGlass",
    "hudGlassStrong",
    "hudBorder",
    "instrumentGlass",
    "instrumentBorder",
    "textPrimary",
    "textSecondary",
    "textDisabled",
    "radiusSm",
    "radiusMd",
    "spacingUnit",
    "fontFamily",
    "emptyValue",
)

PROP_RE = re.compile(
    r"readonly\s+property\s+(?:real|int|string|color)\s+(\w+)\s*:\s*([^/\n]+)"
)


def normalize_value(raw: str) -> str:
    return re.sub(r"\s+", " ", raw.strip().rstrip(","))


def parse_theme(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    return {m.group(1): normalize_value(m.group(2)) for m in PROP_RE.finditer(text)}


def parse_layer_inline_t(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.search(
        r"readonly\s+property\s+QtObject\s+_t\s*:\s*QtObject\s*\{(.*?)\n\s*\}",
        text,
        re.DOTALL,
    )
    if not match:
        raise RuntimeError(f"Could not find _t block in {path}")
    block = match.group(1)
    return {m.group(1): normalize_value(m.group(2)) for m in PROP_RE.finditer(block)}


def main() -> int:
    if not THEME.is_file():
        print(f"ERROR: missing {THEME}", file=sys.stderr)
        return 1
    if not LAYER.is_file():
        print(f"ERROR: missing {LAYER}", file=sys.stderr)
        return 1

    theme = parse_theme(THEME)
    layer = parse_layer_inline_t(LAYER)
    errors: list[str] = []
    warnings: list[str] = []

    for key in REQUIRED_KEYS:
        t_val = theme.get(key)
        l_val = layer.get(key)
        if t_val is None:
            errors.append(f"Theme.qml missing required key: {key}")
        elif l_val is None:
            errors.append(f"FlyViewCustomLayer _t missing required key: {key}")
        elif t_val != l_val:
            errors.append(
                f"HUD token drift [{key}]: Theme={t_val!r} vs Layer={l_val!r}"
            )

    for key in SHARED_KEYS:
        t_val = theme.get(key)
        l_val = layer.get(key)
        if t_val is None or l_val is None:
            continue
        if t_val != l_val:
            warnings.append(
                f"Shared token drift [{key}]: Theme={t_val!r} vs Layer={l_val!r}"
            )

    if warnings:
        print("Warnings:")
        for w in warnings:
            print(f"  - {w}")

    if errors:
        print("HUD token check FAILED:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print(
        f"HUD token check OK ({len(REQUIRED_KEYS)} required, "
        f"{len(warnings)} shared drift warning(s))"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
