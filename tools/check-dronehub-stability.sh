#!/usr/bin/env bash
# DroneHub GCS — Phase 2 stability checks (HUD tokens + QML sync drift).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$ROOT/tools/check-hud-tokens.py"
python3 "$ROOT/tools/check-qml-override-drift.py"
