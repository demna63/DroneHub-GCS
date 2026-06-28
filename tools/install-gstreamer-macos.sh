#!/usr/bin/env bash
# Install QGC-compatible GStreamer on macOS (official universal .pkg → /Library/Frameworks).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GST_VERSION="${GST_VERSION:-1.24.13}"
GST_URL="https://gstreamer.freedesktop.org/data/pkg/osx/${GST_VERSION}"
GST_PKG="gstreamer-1.0-${GST_VERSION}-universal.pkg"
GST_DEV_PKG="gstreamer-1.0-devel-${GST_VERSION}-universal.pkg"
FRAMEWORK="/Library/Frameworks/GStreamer.framework"
GST_H="${FRAMEWORK}/Headers/gst/gst.h"
CACHE="${ROOT}/.cache/gstreamer/${GST_VERSION}"

verify_pkg() {
  local pkg="$1"
  local status
  status="$(pkgutil --check-signature "$pkg" 2>&1 || true)"
  if echo "$status" | grep -qi "package is invalid"; then
    echo "error: corrupt or incomplete pkg (re-downloading): $(basename "$pkg")" >&2
    rm -f "$pkg"
    return 1
  fi
  return 0
}

download_pkg() {
  local name="$1"
  local path="${CACHE}/${name}"
  if [[ -f "$path" ]] && verify_pkg "$path"; then
    echo "==> Using cached ${name}"
    return 0
  fi
  rm -f "$path"
  echo "==> Downloading ${name} (~180–280 MB, do not interrupt)"
  curl -fL --retry 3 --retry-delay 5 --progress-bar -C - -o "$path" "${GST_URL}/${name}"
  verify_pkg "$path"
}

if [[ -f "$GST_H" ]]; then
  echo "==> GStreamer dev headers ready at $FRAMEWORK"
  exit 0
fi

if [[ -d "$FRAMEWORK" ]]; then
  echo "==> GStreamer runtime present but devel headers missing — installing devel pkg"
fi

if ! command -v brew &>/dev/null; then
  echo "error: Homebrew required. Install from https://brew.sh" >&2
  exit 1
fi

export HOMEBREW_NO_AUTO_UPDATE=1
brew list pkgconf &>/dev/null || brew install pkgconf

mkdir -p "$CACHE"

download_pkg "$GST_PKG"
download_pkg "$GST_DEV_PKG"

if [[ ! -d "$FRAMEWORK" ]]; then
  echo "==> Installing GStreamer runtime (sudo password required)"
  sudo installer -pkg "${CACHE}/${GST_PKG}" -target /
fi

echo "==> Installing GStreamer devel headers (sudo password required)"
sudo installer -pkg "${CACHE}/${GST_DEV_PKG}" -target /

if [[ ! -f "$GST_H" ]]; then
  echo "error: $GST_H still missing after install" >&2
  exit 1
fi

echo "==> GStreamer ready: $FRAMEWORK (headers OK)"
