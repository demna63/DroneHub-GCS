#!/usr/bin/env python3
"""Apply batch-4 Georgian translations (Phase 1/2 cleanup).

FlyView HUD strings, MAVLink confirm UI, Joystick guard message.
Also upgrades finished-but-English copies when a curated translation exists.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

SKIP_SOURCES = frozenset({
    "Roll", "Pitch", "Yaw", "Loiter", "Manual", "Stabilize", "Acro", "RTL",
    "Land", "Takeoff", "Hold", "Mission", "Guided", "Auto", "Circle",
    "AMSL", "MGRS", "HDOP", "GPS", "EKF", "PX4", "RTL",
})

SKIP_CONTEXT_RE = re.compile(
    r"(FlightMode|FirmwarePlugin|APM.*Mode|PX4.*Mode|ModeIndicator)$"
)

BATCH4: dict[str, str] = {
    # FlyViewCustomLayer HUD (batch-2 overlap — re-apply after lupdate)
    "Altitude": "სიმაღლე",
    "Ground Speed": "სიჩქარე",
    "Climb Rate": "ასვლის სიჩქარე",
    "Distance": "მანძილი",
    "Satellites": "სატელიტები",
    "Battery": "ბატარეა",
    "Flight Time": "ფრენის დრო",
    "Air Speed": "სისრული სიჩქარე",
    "Current": "დენი",
    "Wind": "ქარი",
    "Temperature": "ტემპერატურა",
    "AMSL": "AMSL",
    # Phase 1 — MAVLink actions UI
    "Other": "სხვა",
    "No data": "მონაცემები არაა",
    "Slide to confirm": "გადაიტანეთ დასადასტურებლად",
    "Slide or hold spacebar": "გაასრიალეთ ან გააჩერეთ spacebar",
    'Action "%1" requires slide confirmation. Use Fly View → Actions.': (
        "მოქმედება „%1“ slide დადასტურებას მოითხოვს. გამოიყენეთ ფრენის ხედი → მოქმედებები."
    ),
    "Mock Link Settings": "Mock Link პარამეტრები",
    # Phase 3 — video status toolbar
    "Video off": "ვიდეო გამორთული",
    "No video backend": "ვიდეო backend არ არის",
    "Video waiting": "ვიდეოს მოლოდინი",
    "Video live": "ვიდეო ცოცხალი",
    "Video status": "ვიდეოს სტატუსი",
    "Off": "გამორთ.",
    "N/A": "N/A",
    "Wait": "მოლოდ.",
    "Live": "Live",
    "Enabled": "ჩართული",
    "Disabled": "გამორთული",
    "Available": "ხელმისაწვდომი",
    "Not compiled": "არ არის კომპილირებული",
    "Backend": "Backend",
    "State": "სტატუსი",
    "Stream": "ნაკადი",
    "Video": "ვიდეო",
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
    applied = 0
    fixed_partial = 0
    upgraded = 0
    skip_ctx = bool(SKIP_CONTEXT_RE.search(context_name))

    def repl_message(match: re.Match[str]) -> str:
        nonlocal applied, fixed_partial, upgraded
        block = match.group(0)
        inner = match.group(1)
        src_m = SOURCE_RE.search(inner)
        tr_m = TRANSLATION_RE.search(inner)
        if not src_m or not tr_m:
            return block

        source = normalize_source(src_m.group(1))
        if not source:
            return block

        existing = tr_m.group(1)
        is_unfinished = 'type="unfinished"' in tr_m.group(0)
        existing_norm = normalize_source(existing)

        if skip_ctx or source in SKIP_SOURCES:
            return block

        ka = BATCH4.get(source)
        if ka is None:
            return block

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

    new_text = CONTEXT_RE.sub(repl_context, text)
    path.write_text(new_text, encoding="utf-8")

    print(f"Applied new translations: {total_applied}")
    print(f"Fixed partial (removed unfinished): {total_fixed}")
    print(f"Upgraded English copies: {total_upgraded}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
