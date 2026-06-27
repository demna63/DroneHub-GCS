#!/usr/bin/env bash
# Run DroneHub GCS from the canonical Release build (avoids stale .app bundles).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
APP="$QGC/build/Release/DroneHubGCS.app"

if [[ ! -d "$QGC" ]]; then
  echo "error: qgroundcontrol/ missing — run ./bootstrap.sh first" >&2
  exit 1
fi

if [[ ! -d "$APP" ]]; then
  echo "error: Release app not found at:" >&2
  echo "  $APP" >&2
  echo "Build with:" >&2
  echo "  cd $QGC && cmake --build build --config Release --target DroneHubGCS" >&2
  exit 1
fi

exec open "$APP"
