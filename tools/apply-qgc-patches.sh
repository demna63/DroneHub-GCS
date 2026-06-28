#!/usr/bin/env bash
# Apply DroneHub patches to the upstream QGC tree (idempotent).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QGC_DIR="${1:-$ROOT/qgroundcontrol}"
PATCHES_DIR="$ROOT/custom/patches"

if [ ! -f "$QGC_DIR/src/QGCApplication.cc" ]; then
  echo "apply-qgc-patches: QGC sources not found at $QGC_DIR" >&2
  exit 1
fi

shopt -s nullglob
patches=("$PATCHES_DIR"/*.patch)
if [ ${#patches[@]} -eq 0 ]; then
  exit 0
fi

for patch in "${patches[@]}"; do
  name="$(basename "$patch")"
  if patch -p1 --dry-run -d "$QGC_DIR" -i "$patch" >/dev/null 2>&1; then
    patch -p1 -d "$QGC_DIR" -i "$patch"
    echo "Applied $name"
  else
    echo "Skipped $name (already applied or not applicable)"
  fi
done
