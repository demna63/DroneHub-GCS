#!/usr/bin/env python3
"""Apply batch-5 Georgian translations (Phase 4 operator UX)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

SKIP_SOURCES = frozenset({
    "Roll", "Pitch", "Yaw", "Loiter", "Manual", "Stabilize", "Acro", "RTL",
    "Land", "Takeoff", "Hold", "Mission", "Guided", "Auto", "Circle",
    "AMSL", "MGRS", "HDOP", "EKF", "PX4", "RTL", "Live",
})

SKIP_CONTEXT_RE = re.compile(
    r"(FlightMode|FirmwarePlugin|APM.*Mode|PX4.*Mode|ModeIndicator)$"
)

BATCH5: dict[str, str] = {
    # Vehicle health toolbar (Phase 4)
    "OK": "OK",
    "Vehicle health": "სისტემის ჯანმრთელობა",
    "Link": "კავშირი",
    "Warn": "ყურ.",
    "Crit": "კრიტ.",
    "No vehicle": "დრონო არ არის",
    "No GPS lock": "GPS lock არაა",
    "sats": "სატ.",
    "Locked": "დაკავშირებული",
    "Link lost": "კავშირი დაკარგული",
    "Link OK": "კავშირი OK",
    "Not supported": "არ არის მხარდაჭერილი",
    "No data": "მონაცემები არაა",
    "Disabled": "გამორთული",
    "Not compiled": "არ არის კომპილირებული",
    "Live": "Live",
    "Flight mode": "ფრენის რეჟიმი",
    "Armed": "შეიარაღებული",
    "Yes": "დიახ",
    "No": "არა",
    "GPS": "GPS",
    "RC link": "RC კავშირი",
    "Battery": "ბატარეა",
    "Video": "ვიდეო",
    "Waiting": "მოლოდინი",
    # Plan toolbar polish
    "Exit Plan": "გეგმიდან გასვლა",
    "Syncing Mission": "მისიის სინქრონიზაცია",
    "Done": "დასრულდა",
    "Click anywhere to hide": "დამალვისთვის დააწკაპუნეთ",
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

        ka = BATCH5.get(source)
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
