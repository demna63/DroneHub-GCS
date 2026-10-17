#!/usr/bin/env python3
"""Guard Georgian drone terminology in the Qt translation files.

Crowdin (and machine translation before it) rendered "vehicle" as a car and
"props" as structural supports, including in safety warnings (fixed in #51), and
machine-translated strings that must stay English, e.g. Pitch -> "მოედანი"
(a football pitch), flight modes, compass letters (Crowdin PR #53).

Rules, per message:
  * source mentions "vehicle"           -> no car words (მანქანა / ავტომობილი)
  * source mentions "prop(s)/propeller" -> no "საყრდენ" (supports)
  * source mentions "motor"             -> no "საავტომობილო" (automotive)
  * [file, context, source] listed in translations/ka-keep-english.json
                                        -> translation must equal the source
    (axis names, flight modes, compass letters, units, protocol names, ...)
  * source already written in Georgian (DroneHub's own strings)
                                        -> translation must equal the source

To deliberately translate a protected string, remove it from the keep list
(or regenerate the list from the current file with --update-keep-list).
"""
from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QGC_TS = ROOT / "translations/qgc_ka.ts"
FILES = (QGC_TS, ROOT / "translations/qgc_json_ka.ts")
KEEP_ENGLISH = ROOT / "translations/ka-keep-english.json"

# Georgian letters, so a match never starts or ends inside another word.
_GEO = "ა-ჿ"
_HAS_GEO = re.compile(rf"[{_GEO}]")
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


def _messages(path: Path):
    """Yield (context, source, translation) for every message in a TS file."""
    root = ET.parse(path).getroot()
    for context in root.iter("context"):
        name = context.findtext("name") or "?"
        for message in context.iter("message"):
            yield name, message.findtext("source") or "", message.findtext("translation") or ""


Key = tuple[str, str, str]   # (file name, context, source)


def _load_keep_list() -> set[Key]:
    if not KEEP_ENGLISH.is_file():
        return set()
    data = json.loads(KEEP_ENGLISH.read_text(encoding="utf-8"))
    return {tuple(entry) for entry in data["entries"]}


def update_keep_list() -> int:
    """Rewrite the keep list from the strings currently left untranslated.

    Keyed per file and context: the same word ("Altitude", "Land") is deliberately
    English in some contexts (flight modes, mission commands) and translated in others.
    """
    keep = sorted({
        (path.name, c, s)
        for path in FILES
        for c, s, t in _messages(path)
        if s and t == s and not _HAS_GEO.search(s)
    })
    KEEP_ENGLISH.write_text(
        json.dumps(
            {
                "_comment": "[file, context, source] entries that must stay English (translation == source). "
                            "Checked by tools/check-ka-terminology.py; regenerate with --update-keep-list.",
                "entries": [list(k) for k in keep],
            },
            ensure_ascii=False,
            indent=1,
        ) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(keep)} protected entries to {KEEP_ENGLISH.relative_to(ROOT)}")
    return 0


def check(path: Path, keep: set[Key]) -> list[str]:
    problems: list[str] = []
    for name, source, translation in _messages(path):
        where = f"{path.name} [{name}] {source[:60]!r}"
        for src_re, bad_re, rule in RULES:
            if src_re.search(source) and (bad := bad_re.search(translation)):
                problems.append(f"{where}: '{bad.group(0)}' ({rule})")
        if translation and translation != source:
            if (path.name, name, source) in keep:
                problems.append(f"{where}: must stay English, got {translation[:40]!r}")
            elif _HAS_GEO.search(source):
                problems.append(f"{where}: Georgian source changed to {translation[:40]!r}")
    return problems


def main() -> int:
    if "--update-keep-list" in sys.argv[1:]:
        return update_keep_list()

    keep = _load_keep_list()
    problems: list[str] = []
    for path in FILES:
        if not path.is_file():
            print(f"ERROR: missing {path}", file=sys.stderr)
            return 1
        problems += check(path, keep)

    if problems:
        print(f"Georgian terminology check FAILED ({len(problems)}):", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(f"Georgian terminology check OK ({len(RULES)} rules, {len(keep)} protected English strings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
