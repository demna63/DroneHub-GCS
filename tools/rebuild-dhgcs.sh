#!/usr/bin/env bash
# Rebuild DroneHub GCS Release binary from the canonical project paths.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
OPEN_APP=false

for arg in "$@"; do
  case "$arg" in
    --open) OPEN_APP=true ;;
  esac
done

if [[ ! -d "$QGC" ]]; then
  echo "error: $QGC missing — run $ROOT/bootstrap.sh first" >&2
  exit 1
fi

echo "==> Rebuilding DroneHubGCS (Release)"
cd "$QGC"
cmake --build build --config Release --target DroneHubGCS

if $OPEN_APP; then
  exec "$ROOT/tools/run-dhgcs.sh"
fi

echo "==> Done: $QGC/build/Release/DroneHubGCS.app"
