#!/usr/bin/env python3
"""Guard Georgian drone terminology in the Qt translation files.

Crowdin (and machine translation before it) rendered "vehicle" as a car and
"props" as structural supports, including in safety warnings. #51 fixed them;
this check fails if a sync brings any of them back.

Rules apply per message, keyed on the English source:
  * source mentions "vehicle"           -> no car words (მანქანა / ავტომობილი)
  * source mentions "prop(s)/propeller" -> no "საყრდენ" (supports)
  * source mentions "motor"             -> no "საავტომობილო" (automotive)
"""
from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = (ROOT / "translations/qgc_ka.ts", ROOT / "translations/qgc_json_ka.ts")

# Georgian letters, so a match never starts or ends inside another word.
_GEO = "ა-ჿ"
RULES: tuple[tuple[re.Pattern[str], re.Pattern[str], str], ...] = (
    (re.compile(r"vehicle", re.I),
     re.compile(rf"(?<![{_GEO}])(?:მანქან|ავტომობილ)[{_GEO}]*"),
     "vehicle = აპარატი"),
    (re.compile(r"\bprop(?:eller)?s?\b", re.I),
     re.compile(rf"(?<![{_GEO}])საყრდენ[{_GEO}]*"),
     "props = პროპელერები"),
    (re.compile(r"\bmotors?\b", re.I),
     re.compile(rf"(?<![{_GEO}])საავტომობილო(?![{_GEO}])"),
     "motor = ძრავა"),
)


def check(path: Path) -> list[str]:
    problems: list[str] = []
    root = ET.parse(path).getroot()
    for context in root.iter("context"):
        name = context.findtext("name") or "?"
        for message in context.iter("message"):
            source = message.findtext("source") or ""
            translation = message.findtext("translation") or ""
            for src_re, bad_re, rule in RULES:
                if src_re.search(source) and (bad := bad_re.search(translation)):
                    problems.append(
                        f"{path.name} [{name}] {source[:60]!r}: "
                        f"'{bad.group(0)}' ({rule})"
                    )
    return problems


def main() -> int:
    problems: list[str] = []
    for path in FILES:
        if not path.is_file():
            print(f"ERROR: missing {path}", file=sys.stderr)
            return 1
        problems += check(path)

    if problems:
        print(f"Georgian terminology check FAILED ({len(problems)}):", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(f"Georgian terminology check OK ({len(RULES)} rules, {len(FILES)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
