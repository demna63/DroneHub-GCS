#!/usr/bin/env python3
"""Print qgc_ka.ts translation coverage summary (active messages only)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"

MESSAGE_RE = re.compile(r"<message>(.*?)</message>", re.DOTALL)
SOURCE_RE = re.compile(r"<source>(.*?)</source>", re.DOTALL)
TRANSLATION_RE = re.compile(
    r'<translation(?:\s+type="([^"]*)")?>(.*?)</translation>',
    re.DOTALL,
)


def has_georgian(text: str) -> bool:
    return any("\u10a0" <= c <= "\u10ff" for c in text)


def main() -> int:
    path = TS if len(sys.argv) < 2 else Path(sys.argv[1])
    if not path.is_file():
        print(f"ERROR: missing {path}", file=sys.stderr)
        return 1

    text = path.read_text(encoding="utf-8")
    active = georgian = unfinished = english_copy = empty = 0

    for match in MESSAGE_RE.finditer(text):
        block = match.group(1)
        if 'type="vanished"' in block:
            continue
        active += 1
        src_m = SOURCE_RE.search(block)
        tr_m = TRANSLATION_RE.search(block)
        if not src_m or not tr_m:
            continue
        source = src_m.group(1).strip()
        ttype = tr_m.group(1) or ""
        translation = tr_m.group(2).strip()
        if ttype == "unfinished":
            unfinished += 1
            continue
        if not translation:
            empty += 1
        elif has_georgian(translation):
            georgian += 1
        elif translation == source:
            english_copy += 1

    print(f"File: {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}")
    print(f"Active messages:     {active}")
    print(f"Georgian:            {georgian}")
    print(f"Unfinished:          {unfinished}")
    print(f"Intentional English: {english_copy}")
    print(f"Empty translation:   {empty}")

    if unfinished:
        print("\nUnfinished entries:", file=sys.stderr)
        for match in MESSAGE_RE.finditer(text):
            block = match.group(1)
            if 'type="vanished"' in block:
                continue
            tr_m = TRANSLATION_RE.search(block)
            src_m = SOURCE_RE.search(block)
            if tr_m and (tr_m.group(1) or "") == "unfinished" and src_m:
                ctx = re.search(
                    r"<context>\s*<name>(.*?)</name>.*?"
                    + re.escape(match.group(0))
                    + r".*?</context>",
                    text,
                    re.DOTALL,
                )
                ctx_name = ctx.group(1) if ctx else "?"
                print(f"  - [{ctx_name}] {src_m.group(1).strip()!r}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
