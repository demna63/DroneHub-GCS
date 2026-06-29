#!/usr/bin/env bash
# DroneHub GCS — Phase 3 runtime smoke (static checks + optional live SITL).
#
# Usage:
#   ./tools/smoke-runtime.sh              # static only (CI-friendly)
#   ./tools/smoke-runtime.sh --live       # launch GCS + MAVLink simulator
#   ./tools/smoke-runtime.sh --live -y    # skip confirmation prompt
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
GCS_APP="$QGC/build/Release/DroneHubGCS.app"
SIM="$ROOT/tools/simulate-mavlink-udp.py"
LIVE=false
ASSUME_YES="${ASSUME_YES:-0}"

for arg in "$@"; do
  case "$arg" in
    --live) LIVE=true ;;
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

step() { echo ""; echo "==> $*"; }

step "Stability (HUD tokens + QML sync drift)"
"$ROOT/tools/check-dronehub-stability.sh"

step "Translation inventory"
"$ROOT/tools/check-translation-stats.py"

step "Video build"
"$ROOT/tools/check-video-build.sh"

step "Binary + custom plugin markers"
[[ -d "$GCS_APP" ]] || { echo "error: GCS not built — run tools/rebuild-dhgcs.sh" >&2; exit 1; }
BIN="$GCS_APP/Contents/MacOS/DroneHubGCS"
[[ -x "$BIN" ]] || BIN="$QGC/build/Release/DroneHubGCS"
[[ -x "$BIN" ]] || { echo "error: DroneHubGCS executable not found" >&2; exit 1; }

if [[ -f "$QGC/src/QmlControls/MavlinkAction.h" ]]; then
  grep -q 'requiresConfirm' "$QGC/src/QmlControls/MavlinkAction.h" \
    || { echo "error: MavlinkAction confirm patch not applied" >&2; exit 1; }
fi
echo "Binary OK: $BIN"

if ! $LIVE; then
  echo ""
  echo "smoke-runtime: static checks PASSED"
  echo "  For live HUD test: ./tools/smoke-runtime.sh --live"
  exit 0
fi

if [[ "$ASSUME_YES" != "1" && -t 0 ]]; then
  read -r -p "Live smoke stops running DroneHubGCS/px4 and starts GCS + simulator. Continue? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "aborted" >&2; exit 1 ;;
  esac
fi

step "Live session (GCS + MAVLink simulator)"
killall px4 2>/dev/null || true
killall DroneHubGCS 2>/dev/null || true
sleep 1

open "$GCS_APP"

ready=0
for ((i = 1; i <= 90; i++)); do
  if lsof -nP -iUDP:14550 2>/dev/null | grep -q ':14550'; then
    ready=1
    echo "GCS listening on UDP 14550 (${i}s)"
    break
  fi
  sleep 1
done

(( ready == 1 )) || echo "warning: UDP 14550 not detected — continuing"

command -v python3 >/dev/null || { echo "error: python3 required" >&2; exit 1; }
python3 -c "import pymavlink" 2>/dev/null || { echo "error: pip3 install pymavlink" >&2; exit 1; }

python3 "$SIM" &
sim_pid=$!
trap 'kill $sim_pid 2>/dev/null || true' EXIT

echo "Simulator PID $sim_pid — running 12s (open Fly View, verify HUD telemetry)"
sleep 12

if kill -0 "$sim_pid" 2>/dev/null; then
  echo "Simulator still running — OK"
else
  echo "error: simulator exited early" >&2
  exit 1
fi

echo ""
echo "smoke-runtime: static + live checks PASSED"
echo "  Manual: confirm HUD metrics update and toolbar video chip (Off/Wait/Live)"
