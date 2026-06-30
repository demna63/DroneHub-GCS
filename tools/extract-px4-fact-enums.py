#!/usr/bin/env python3
"""Seed FactEnum entries in qgc_ka.ts from PX4 parameter XML enum values.

Setup summary rows (enumStringValue) and parameter combo boxes read enum labels
loaded from PX4ParameterFactMetaData.xml or vehicle JSON metadata. DroneHub
localizes them via QCoreApplication::translate("FactEnum", ...) in FactMetaData.

This script adds missing <message> stubs under the FactEnum context so lupdate
and Crowdin can track them. Run apply-ka-batch6.py (or Crowdin) for Georgian text.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TS = ROOT / "translations" / "qgc_ka.ts"
PX4_XML = (
    ROOT
    / "qgroundcontrol"
    / "src"
    / "FirmwarePlugin"
    / "PX4"
    / "PX4ParameterFactMetaData.xml"
)

VALUE_RE = re.compile(r'<value code="[^"]*">([^<]+)</value>')
FACT_ENUM_CTX_RE = re.compile(
    r"(<context>\s*<name>FactEnum</name>)(.*?)(</context>)",
    re.DOTALL,
)
EXISTING_SOURCE_RE = re.compile(r"<source>(.*?)</source>", re.DOTALL)


def xml_escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def collect_px4_enum_strings() -> list[str]:
    if not PX4_XML.is_file():
        print(f"error: PX4 metadata not found at {PX4_XML}", file=sys.stderr)
        print("hint: run ./bootstrap.sh first", file=sys.stderr)
        return []
    text = PX4_XML.read_text(encoding="utf-8")
    values = sorted({m.group(1).strip() for m in VALUE_RE.finditer(text) if m.group(1).strip()})
    return values


def existing_fact_enum_sources(ts_text: str) -> set[str]:
    m = FACT_ENUM_CTX_RE.search(ts_text)
    if not m:
        return set()
    body = m.group(2)
    return {
        s.replace("&apos;", "'").replace("&quot;", '"').strip()
        for s in EXISTING_SOURCE_RE.findall(body)
    }


def message_block(source: str) -> str:
    esc = xml_escape(source)
    return (
        "    <message>\n"
        f"        <source>{esc}</source>\n"
        f"        <translation type=\"unfinished\">{esc}</translation>\n"
        "    </message>\n"
    )


def main() -> int:
    ts_path = Path(sys.argv[1]) if len(sys.argv) > 1 else TS
    px4_values = collect_px4_enum_strings()
    if not px4_values:
        return 1

    text = ts_path.read_text(encoding="utf-8")
    existing = existing_fact_enum_sources(text)
    missing = [v for v in px4_values if v not in existing]

    if not missing:
        print(f"FactEnum: all {len(px4_values)} PX4 enum strings already in {ts_path.name}")
        return 0

    m = FACT_ENUM_CTX_RE.search(text)
    if not m:
        print("error: FactEnum context not found in qgc_ka.ts", file=sys.stderr)
        return 1

    insert = "".join(message_block(s) for s in missing)
    new_ctx = f"{m.group(1)}{m.group(2)}{insert}{m.group(3)}"
    text = text[: m.start()] + new_ctx + text[m.end() :]
    ts_path.write_text(text, encoding="utf-8")
    print(f"Added {len(missing)} FactEnum stub(s) to {ts_path.name} ({len(existing)} already present)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
