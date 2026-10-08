#!/usr/bin/env bash
# Rebuild DroneHub GCS Release binary from the canonical project paths.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
OPEN_APP=false
WITH_VIDEO=false
RECONFIGURE=false
STABILITY_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --open) OPEN_APP=true ;;
    --with-video) WITH_VIDEO=true; RECONFIGURE=true ;;
    --reconfigure) RECONFIGURE=true ;;
    --check-stability) STABILITY_ONLY=true ;;
  esac
done

if [[ ! -d "$QGC" ]]; then
  echo "error: $QGC missing — run $ROOT/bootstrap.sh first" >&2
  exit 1
fi

if $STABILITY_ONLY; then
  exec "$ROOT/tools/check-dronehub-stability.sh"
fi

QT_VERSION="${QT_VERSION:-6.11.1}"   # QGC v5.1.x pin (.github/build-config.json)
if [[ -z "${QT_PREFIX:-}" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    QT_PREFIX="$HOME/Qt/${QT_VERSION}/macos"
  else
    QT_PREFIX="$HOME/Qt/${QT_VERSION}/gcc_64"
  fi
fi

# QGC 5.1 bootstraps qgroundcontrol/.venv and needs Python >= 3.10 (macOS /usr/bin/python3 is 3.9).
if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix)/opt/python@3.12/libexec/bin" ]]; then
  export PATH="$(brew --prefix)/opt/python@3.12/libexec/bin:$PATH"
fi

# Local macOS builds are arm64-only (universal x86_64h;arm64 is for release CI).
OSX_ARCH_FLAG=()
if [[ "$(uname -s)" == "Darwin" ]]; then
  OSX_ARCH_FLAG=(-DCMAKE_OSX_ARCHITECTURES="${DRONEHUB_OSX_ARCHS:-arm64}")
fi

if $WITH_VIDEO; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    "$ROOT/tools/install-gstreamer-macos.sh"
  else
    echo "error: --with-video auto-install is macOS-only; install GStreamer per QGC docs, then reconfigure with -DQGC_ENABLE_GST_VIDEOSTREAMING=ON" >&2
    exit 1
  fi
  RECONFIGURE=true
fi

if $RECONFIGURE || [[ ! -f "$QGC/build/CMakeCache.txt" ]]; then
  GST_FLAG=OFF
  if $WITH_VIDEO || [[ "${DRONEHUB_GST_VIDEO:-}" == "1" ]]; then
    GST_FLAG=ON
  elif [[ -f "$QGC/build/CMakeCache.txt" ]]; then
    cached="$(rg -m1 '^QGC_ENABLE_GST_VIDEOSTREAMING:BOOL=' "$QGC/build/CMakeCache.txt" 2>/dev/null | cut -d= -f2 || true)"
    [[ "$cached" == "ON" ]] && GST_FLAG=ON
  fi

  echo "==> Configuring DroneHubGCS (Release, GStreamer=${GST_FLAG})"
  cmake -S "$QGC" -B "$QGC/build" -G Ninja \
    -DCMAKE_PREFIX_PATH="$QT_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DQGC_CUSTOM_BUILD=ON \
    -DQGC_ENABLE_GST_VIDEOSTREAMING="${GST_FLAG}" \
    "${OSX_ARCH_FLAG[@]}"
fi

echo "==> Rebuilding DroneHubGCS (Release)"
"$ROOT/tools/check-dronehub-stability.sh"
cd "$QGC"
cmake --build build --config Release --target DroneHubGCS

"$ROOT/tools/sync-dhgcs-app.sh" "$QGC/build"

if $WITH_VIDEO || [[ "${DRONEHUB_GST_VIDEO:-}" == "1" ]]; then
  if rg -q '^QGC_ENABLE_GST_VIDEOSTREAMING:BOOL=ON' "$QGC/build/CMakeCache.txt" 2>/dev/null; then
    echo "==> Video: GStreamer enabled (QGC_GST_STREAMING compiled in)"
    echo "    In app: Application Settings → Video → set source (UDP H.264 / RTSP)"
  else
    echo "!!  Video: GStreamer still OFF in CMakeCache — rerun with --with-video" >&2
  fi
fi

if $OPEN_APP; then
  exec "$ROOT/tools/run-dhgcs.sh"
fi

echo "==> Done. Open:"
echo "  ${HOME}/Desktop/DroneHubGCS.app"
