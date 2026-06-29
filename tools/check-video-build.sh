#!/usr/bin/env bash
# Verify DroneHub GCS was built with video support (GStreamer) when expected.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QGC="$ROOT/qgroundcontrol"
CACHE="$QGC/build/CMakeCache.txt"

die() { echo "check-video-build: $*" >&2; exit 1; }

[[ -f "$CACHE" ]] || die "CMake cache missing — run tools/rebuild-dhgcs.sh first"

gst_flag="$(rg -m1 '^QGC_ENABLE_GST_VIDEOSTREAMING:BOOL=' "$CACHE" | cut -d= -f2 || true)"
if [[ "$gst_flag" != "ON" ]]; then
  echo "check-video-build: GStreamer OFF (CI/default build — video receiver not compiled)"
  echo "  Rebuild with: tools/rebuild-dhgcs.sh --with-video"
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  [[ -f /Library/Frameworks/GStreamer.framework/Headers/gst/gst.h ]] \
    || die "GStreamer.framework missing — run tools/install-gstreamer-macos.sh"
fi

# Locate Release binary (macOS .app or Linux flat binary).
BIN=""
for candidate in \
  "$QGC/build/Release/DroneHubGCS.app/Contents/MacOS/DroneHubGCS" \
  "$QGC/build/Release/DroneHubGCS" \
  "$QGC/build/DroneHubGCS"; do
  if [[ -x "$candidate" ]]; then
    BIN="$candidate"
    break
  fi
done

[[ -n "$BIN" ]] || die "DroneHubGCS binary not found — run tools/rebuild-dhgcs.sh"

if otool -L "$BIN" 2>/dev/null | grep -Fq 'GStreamer.framework'; then
  echo "check-video-build OK (GStreamer ON, framework linked in binary)"
  exit 0
fi

die "GStreamer enabled in CMake but GStreamer.framework not linked in $BIN"
