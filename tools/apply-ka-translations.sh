#!/usr/bin/env bash
# Apply curated Georgian translation batches to translations/qgc_ka.ts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
python3 "$ROOT/apply-ka-batch2.py" "$@"
python3 "$ROOT/apply-ka-batch3.py" "$@"
python3 "$ROOT/apply-ka-batch4.py" "$@"
python3 "$ROOT/apply-ka-batch5.py" "$@"
