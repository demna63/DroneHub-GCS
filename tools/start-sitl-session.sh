#!/usr/bin/env bash
# Start DroneHub GCS first, wait for UDP 14550, then launch vehicle (PX4 SITL or simulator).
#
# Usage:
#   ./tools/start-sitl-session.sh              # PX4 none_iris if built, else simulator
#   ./tools/start-sitl-session.sh --simulator  # pymavlink only (no PX4)
#   ./tools/start-sitl-session.sh --px4        # force PX4 none_iris
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GCS_APP="$ROOT/qgroundcontrol/build/Release/DroneHubGCS.app"
PX4="${PX4_DIR:-$HOME/Desktop/PX4-Autopilot}"
PX4_BIN="$PX4/build/px4_sitl_default/bin/px4"
PX4_TARGET="${PX4_SITL_TARGET:-none_iris}"
SIM="$ROOT/tools/simulate-mavlink-udp.py"
GCS_WAIT_SEC="${GCS_WAIT_SEC:-90}"
MODE="auto"

for arg in "$@"; do
  case "$arg" in
    --simulator) MODE="simulator" ;;
    --px4)       MODE="px4" ;;
    -h|--help)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *)
      echo "unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }

[[ -d "$GCS_APP" ]] || die "GCS not built — run: $ROOT/tools/rebuild-dhgcs.sh"

if [[ "$MODE" == "auto" ]]; then
  if [[ -x "$PX4_BIN" ]]; then
    MODE="px4"
  else
    MODE="simulator"
  fi
fi

if [[ "$MODE" == "px4" ]]; then
  [[ -d "$PX4" ]] || die "PX4 not found at $PX4 (set PX4_DIR)"
  [[ -x "$PX4_BIN" ]] || die "PX4 SITL not built — run: cd $PX4 && make px4_sitl $PX4_TARGET"
fi

echo "==> DroneHub SITL session (GCS first, then vehicle)"
echo "    mode: $MODE"
echo ""

echo "[1/4] Stop stale px4 / GCS instances..."
killall px4 2>/dev/null || true
killall DroneHubGCS 2>/dev/null || true
# PX4 SITL sometimes survives a plain killall on macOS.
if pgrep -qx px4; then
  killall -9 px4 2>/dev/null || true
  sleep 1
fi
sleep 1

echo "[2/4] Launch DroneHubGCS..."
open "$GCS_APP"

echo "[3/4] Wait until GCS listens on UDP 14550 (up to ${GCS_WAIT_SEC}s)..."
ready=0
for ((i = 1; i <= GCS_WAIT_SEC; i++)); do
  # macOS lsof truncates COMMAND (~9 chars) — match port binding, not process name.
  if lsof -nP -iUDP:14550 2>/dev/null | grep -q ':14550'; then
    ready=1
    echo "    GCS ready on UDP 14550 (${i}s)"
    break
  fi
  sleep 1
done

if (( ready == 0 )); then
  echo "    warning: UDP 14550 not detected — continuing anyway"
  echo "    (open Fly View manually; AutoConnect UDP must be ON)"
  sleep 5
fi

echo "[4/4] Start vehicle..."
if [[ "$MODE" == "px4" ]]; then
  echo "    PX4 ${PX4_TARGET} → MAVLink to localhost:14550"
  echo "    (override: PX4_SITL_TARGET=sihsim_quadx for built-in physics sim)"
  echo "    Ctrl+C stops PX4 (GCS keeps running)"
  echo ""
  cd "$PX4"
  exec make "px4_sitl" "$PX4_TARGET"
else
  command -v python3 >/dev/null || die "python3 not found"
  python3 -c "import pymavlink" 2>/dev/null || die "run: pip3 install pymavlink"
  echo "    MAVLink simulator → localhost:14550"
  echo "    Ctrl+C to stop"
  echo ""
  exec python3 "$SIM"
fi
