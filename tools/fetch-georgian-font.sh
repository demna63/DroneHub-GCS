#!/usr/bin/env bash
# Download Noto Sans Georgian (OFL) into custom/res/fonts/NotoSansGeorgian.ttf
# Used by bootstrap.sh and CI when the gitignored font file is missing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_DIR="${FONT_DIR:-$ROOT/custom/res/fonts}"
FONT_FILE="$FONT_DIR/NotoSansGeorgian.ttf"
VF_NAME='NotoSansGeorgian%5Bwdth%2Cwght%5D.ttf'

mkdir -p "$FONT_DIR"

if [ -f "$FONT_FILE" ] && [ -s "$FONT_FILE" ]; then
  echo "==> Georgian font OK: $FONT_FILE"
  exit 0
fi

echo "==> Fetching Noto Sans Georgian (OFL)..."

download() {
  local url="$1"
  echo "    try: $url"
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 "$url" -o "$FONT_FILE.tmp"
}

URLS=(
  "https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/notosansgeorgian/${VF_NAME}"
  "https://raw.githubusercontent.com/google/fonts/main/ofl/notosansgeorgian/${VF_NAME}"
  "https://github.com/google/fonts/raw/main/ofl/notosansgeorgian/${VF_NAME}"
)

for url in "${URLS[@]}"; do
  if download "$url"; then
    mv "$FONT_FILE.tmp" "$FONT_FILE"
    echo "==> Saved: $FONT_FILE ($(wc -c < "$FONT_FILE" | tr -d ' ') bytes)"
    exit 0
  fi
  rm -f "$FONT_FILE.tmp"
done

echo "!!  Georgian font download failed (network?)." >&2
echo "    Build still works; Georgian glyphs may render as boxes." >&2
echo "    Manual: copy NotoSansGeorgian.ttf → custom/res/fonts/ (see PLACE_FONT_HERE.md)" >&2
exit 1
