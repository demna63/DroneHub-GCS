#!/usr/bin/env python3
"""Apply batch-6 Georgian translations — FactEnum (PX4 parameter enum labels).

Targets Setup summary rows (enumStringValue), parameter combo boxes, and bitmask labels.
Skips flight-mode names (COM_FLTMODE*) and acronyms per project safety rule.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

# Flight-mode parameter enum values stay English (operator safety).
SKIP_SOURCES = frozenset({
    "Roll", "Pitch", "Yaw", "Loiter", "Manual", "Stabilize", "Acro", "RTL",
    "Land", "Takeoff", "Hold", "Mission", "Guided", "Auto", "Circle",
    "Training", "FBW A", "FBW B", "Cruise", "Autotune", "QStabilize",
    "QHover", "QLoiter", "QLand", "QRTL", "QAcro", "QAutotune",
    "AutoTune", "Offboard", "Ready", "Terminate", "Precision Land",
})

TARGET_CONTEXT = "FactEnum"

BATCH6: dict[str, str] = {
    # Setup summary — power / battery
    "Unassigned": "მიუნიშნავი",
    "Power Module": "ძალის მოდული",
    "External": "გარე",
    "ESCs": "ESC-ები",
    "Analog": "ანალოგური",
    "Digital": "ციფრული",
    # Failsafe / safety (SafetyComponentSummary)
    "Disabled": "გამორთული",
    "Warning": "გაფრთხილება",
    "Hold mode": "Hold რეჟიმი",
    "Return mode": "Return რეჟიმი",
    "Land mode": "Land რეჟიმი",
    "Disarm": "დისარმი",
    "Terminate": "შეწყვეტა",
    "Return at critical level, land at emergency level": "კრიტიკულ დონეზე დაბრუნება, ავარიულზე დაჯახვა",
    "Enabled": "ჩართული",
    # Airframe / sensors common
    "Generic": "ზოგადი",
    "Simulation": "სიმულაცია",
    "No Rotation": "როტაციის გარეშე",
    "Yaw 45°": "Yaw 45°",
    "Yaw 90°": "Yaw 90°",
    "Yaw 135°": "Yaw 135°",
    "Yaw 180°": "Yaw 180°",
    "Yaw 225°": "Yaw 225°",
    "Yaw 270°": "Yaw 270°",
    "Yaw 315°": "Yaw 315°",
    "Custom": "მორგებული",
    "None": "არცერთი",
    "(Not set)": "(არ არის დაყენებული)",
    # RC / modes setup
    "Setup required": "გამართვა საჭიროა",
}

CONTEXT_RE = re.compile(
    r"<context>\s*<name>(.*?)</name>(.*?)</context>",
    re.DOTALL,
)
MESSAGE_RE = re.compile(r"<message>(.*?)</message>", re.DOTALL)
SOURCE_RE = re.compile(r"<source>(.*?)</source>", re.DOTALL)
TRANSLATION_RE = re.compile(
    r"<translation(?:\s+type=\"unfinished\")?>(.*?)</translation>",
    re.DOTALL,
)


def xml_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def normalize_source(raw: str) -> str:
    return raw.replace("&apos;", "'").replace("&quot;", '"').strip()


def has_georgian(text: str) -> bool:
    return any("\u10a0" <= c <= "\u10ff" for c in text)


def process_context(context_name: str, body: str) -> tuple[str, int, int, int]:
    if context_name != TARGET_CONTEXT:
        return body, 0, 0, 0

    applied = 0
    fixed_partial = 0
    upgraded = 0

    def repl_message(match: re.Match[str]) -> str:
        nonlocal applied, fixed_partial, upgraded
        block = match.group(0)
        inner = match.group(1)
        src_m = SOURCE_RE.search(inner)
        tr_m = TRANSLATION_RE.search(inner)
        if not src_m or not tr_m:
            return block

        source = normalize_source(src_m.group(1))
        if not source or source in SKIP_SOURCES:
            return block

        ka = BATCH6.get(source)
        if ka is None:
            return block

        existing = tr_m.group(1)
        is_unfinished = 'type="unfinished"' in tr_m.group(0)
        existing_norm = normalize_source(existing)

        if ka == source and not is_unfinished:
            return block

        needs_apply = is_unfinished or existing_norm == source or (
            not has_georgian(existing_norm) and existing_norm != ka
        )
        if not needs_apply:
            return block

        new_tr = f"<translation>{xml_escape(ka)}</translation>"
        if is_unfinished and existing.strip() and existing != source:
            fixed_partial += 1
        elif not is_unfinished and existing_norm == source:
            upgraded += 1
        else:
            applied += 1
        return block.replace(tr_m.group(0), new_tr, 1)

    new_body = MESSAGE_RE.sub(repl_message, body)
    return new_body, applied, fixed_partial, upgraded


def main() -> int:
    path = TS
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])

    text = path.read_text(encoding="utf-8")
    total_applied = 0
    total_fixed = 0
    total_upgraded = 0

    def repl_context(match: re.Match[str]) -> str:
        nonlocal total_applied, total_fixed, total_upgraded
        name = match.group(1)
        body = match.group(2)
        new_body, applied, fixed, upgraded = process_context(name, body)
        total_applied += applied
        total_fixed += fixed
        total_upgraded += upgraded
        return f"<context>\n    <name>{name}</name>{new_body}</context>"

    text = CONTEXT_RE.sub(repl_context, text)
    path.write_text(text, encoding="utf-8")
    print(
        f"batch6 ({TARGET_CONTEXT}): applied={total_applied} "
        f"fixed_partial={total_fixed} upgraded={total_upgraded}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
