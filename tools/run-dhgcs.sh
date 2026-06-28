#!/usr/bin/env bash
# Run DroneHub GCS (build/DroneHubGCS.app symlinks to Release after each build).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
APP="$QGC/build/DroneHubGCS.app"
RELEASE_APP="$QGC/build/Release/DroneHubGCS.app"

if [[ ! -d "$QGC" ]]; then
  echo "error: qgroundcontrol/ missing — run ./bootstrap.sh first" >&2
  exit 1
fi

if [[ ! -d "$RELEASE_APP" ]]; then
  echo "error: app not built yet:" >&2
  echo "  $RELEASE_APP" >&2
  echo "Build with:" >&2
  echo "  $ROOT/tools/rebuild-dhgcs.sh" >&2
  exit 1
fi

"$ROOT/tools/sync-dhgcs-app.sh" "$QGC/build"

if [[ ! -d "$RELEASE_APP" ]]; then
  echo "error: could not prepare Release bundle at $RELEASE_APP" >&2
  exit 1
fi

killall DroneHubGCS 2>/dev/null || true
sleep 0.5

exec open "$RELEASE_APP"
