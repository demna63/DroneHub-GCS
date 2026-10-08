#!/usr/bin/env python3
"""Apply a {source: georgian} JSON batch to translations/qgc_ka.ts.

Fills every <message> whose <source> matches a key (all contexts), marks it finished.
Usage: tools/apply-ka-batch-json.py tools/ka-batch-qgc51.json [translations/qgc_ka.ts]
"""
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root_dir = Path(__file__).resolve().parent.parent
batch = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
ts_path = Path(sys.argv[2]) if len(sys.argv) > 2 else root_dir / "translations" / "qgc_ka.ts"

tree = ET.parse(ts_path)
applied = 0
for msg in tree.getroot().iter("message"):
    src = msg.findtext("source")
    tr = msg.find("translation")
    if tr is None or msg.get("numerus") == "yes" or src not in batch:
        continue
    tr.text = batch[src]
    tr.attrib.pop("type", None)
    applied += 1

tree.write(ts_path, encoding="utf-8", xml_declaration=True)
text = ts_path.read_text(encoding="utf-8")
if "<!DOCTYPE TS>" not in text:
    text = text.replace("?>\n", "?>\n<!DOCTYPE TS>\n", 1)
    ts_path.write_text(text, encoding="utf-8")
left = sum(1 for m in tree.getroot().iter("message")
           if m.find("translation") is not None and m.find("translation").get("type") == "unfinished")
print(f"applied {applied} message(s); unfinished left: {left}")
