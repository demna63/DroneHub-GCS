#!/usr/bin/env bash
# Apply DroneHub patches to the upstream QGC tree (idempotent).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QGC_DIR="${1:-$ROOT/qgroundcontrol}"
PATCHES_DIR="$ROOT/custom/patches"
if [ ! -d "$PATCHES_DIR" ] && [ -d "${QGC_DIR}/custom/patches" ]; then
  PATCHES_DIR="${QGC_DIR}/custom/patches"
fi

# Git for Windows ships patch in usr/bin (not always on PATH when CMake spawns bash).
if [[ "${OS:-}" == "Windows_NT" ]] || [[ "$(uname -s 2>/dev/null)" == MINGW* ]]; then
  for _patch_dir in \
      "/c/Program Files/Git/usr/bin" \
      "/c/Program Files (x86)/Git/usr/bin" \
      "${ProgramFiles:-/c/Program Files}/Git/usr/bin"; do
    if [[ -x "${_patch_dir}/patch.exe" ]]; then
      PATH="${_patch_dir}:${PATH}"
      export PATH
      break
    fi
  done
fi

if ! command -v patch >/dev/null 2>&1; then
  echo "apply-qgc-patches: patch command not found (install Git for Windows or patch)" >&2
  exit 1
fi

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
