#!/usr/bin/env bash
# DroneHub GCS — connection checklist (PX4 SITL or MAVLink simulator).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GCS_APP="$ROOT/qgroundcontrol/build/Release/DroneHubGCS.app"
SIM="$ROOT/tools/simulate-mavlink-udp.py"

echo "==> DroneHub connection checklist"
echo ""

echo "1) Stop stale processes (important if PX4 says 'already running')"
echo "   killall px4 2>/dev/null || true"
echo "   killall DroneHubGCS 2>/dev/null || true"
echo ""

echo "2) Start GCS FIRST (must listen UDP 14550 before vehicle)"
if [[ -d "$GCS_APP" ]]; then
  open "$GCS_APP"
  echo "   opened: $GCS_APP"
else
  echo "   !! build first: $ROOT/tools/rebuild-dhgcs.sh"
fi
echo "   wait ~5s for Fly View to load"
echo ""

echo "3a) Option A — PX4 SITL (no Gazebo):"
echo "   cd ~/Desktop/PX4-Autopilot   # or your PX4 path"
echo "   make px4_sitl none_iris"
echo ""
echo "3b) Option B — lightweight simulator (no PX4 build):"
echo "   pip3 install pymavlink"
echo "   python3 $SIM"
echo ""

echo "4) Verify"
echo "   pgrep -l px4          # Option A"
echo "   lsof -iUDP:14550      # GCS listening"
echo "   Toolbar should NOT say disconnected"
echo ""

echo "5) Still disconnected?"
echo "   • Only ONE GCS app (Dock: use build/Release/DroneHubGCS.app only)"
echo "   • Settings → General → AutoConnect UDP = ON"
echo "   • Toolbar status → manual Connect → UDP, port 14550"
echo "   • Rebuild GCS: $ROOT/tools/rebuild-dhgcs.sh"
echo ""
echo "6) Offline tests (no link needed)"
echo "   • Plan View → გეგმა → Waypoint → click map"
echo "   • HUD shows — when disconnected (expected)"
