#!/usr/bin/env bash
# DroneHub GCS — field / SITL smoke test helper (macOS/Linux).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
APP="$QGC/build/Release/DroneHubGCS.app"
SIM="$ROOT/tools/simulate-mavlink-udp.py"
PX4="${PX4_DIR:-$HOME/Desktop/PX4-Autopilot}"

echo "==> DroneHub GCS field test"
echo "    project: $ROOT"
echo ""

echo "1) Rebuild (only if you changed C++ / qmlcache sources)"
echo "   cd $QGC"
echo "   cmake --build build --config Release --target DroneHubGCS"
echo ""

echo "2) Launch GCS"
if [[ -d "$APP" ]]; then
  open "$APP"
  echo "   opened: $APP"
else
  echo "   !! Release app missing — run rebuild step above"
fi

echo ""
echo "3) Simulate vehicle (no PX4 install needed)"
echo "   pip3 install pymavlink    # once"
echo "   python3 $SIM"
echo "   (separate terminal, keep running; QGC AutoConnect UDP → port 14550)"
echo ""

if [[ -d "$PX4" ]]; then
  echo "4) Or real PX4 SITL (found at $PX4)"
  echo "   cd $PX4"
  echo "   make px4_sitl gz_x500"
else
  echo "4) PX4 SITL (optional — not installed)"
  echo "   git clone https://github.com/PX4/PX4-Autopilot.git $PX4"
  echo "   cd $PX4 && make px4_sitl gz_x500"
  echo "   (large download + build; see docs.px4.io dev setup)"
fi

echo ""
echo "5) Fly View checks"
echo "   - Toolbar: connected status (Georgian)"
echo "   - HUD: live altitude / speed / battery (not —)"
echo "   - Expand / Clean map toggles"
echo ""
echo "6) Plan View offline (no simulator needed)"
echo "   Left nav → Plan → Waypoint tool → click map"
