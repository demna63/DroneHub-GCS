#!/usr/bin/env bash
# DroneHub GCS — field / SITL smoke test helper (macOS/Linux).
# Launches the app and prints connection steps for PX4 SITL over UDP.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN="$ROOT/tools/run-dhgcs.sh"

echo "==> DroneHub GCS field test"
echo ""
echo "1) Launch GCS"
if [[ -x "$RUN" ]]; then
  "$RUN"
else
  echo "   run-dhgcs.sh not found — open Release .app manually"
fi

echo ""
echo "2) PX4 SITL (separate terminal, if PX4-Autopilot is installed)"
echo "   cd ~/PX4-Autopilot   # or your clone path"
echo "   make px4_sitl gz_x500"
echo ""
echo "3) QGC connection"
echo "   DroneHubGCS auto-connects UDP (port 14550) when AutoConnect is enabled."
echo "   Settings → General → AutoConnect → UDP should be ON (default in Daily.ini)."
echo ""
echo "4) Fly View checks"
echo "   - Toolbar status shows connected vehicle (Georgian strings)"
echo "   - Bottom HUD: altitude, speed, battery update (not em-dash)"
echo "   - Expand: secondary telemetry rows"
echo "   - Clean map: satellite toggle"
echo ""
echo "5) Plan View (offline, no vehicle)"
echo "   - Left nav → Plan"
echo "   - Waypoint tool → click map → numbered waypoints"
echo "   - Offline defaults: PX4 / MultiRotor (CustomPlugin)"
echo ""
echo "No PX4? Install: https://docs.px4.io/main/en/dev_setup/building_px4.html"
echo "Or connect a real vehicle via USB radio / Wi‑Fi telemetry."
