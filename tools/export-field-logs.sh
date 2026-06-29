#!/usr/bin/env bash
# DroneHub GCS — field support bundle (logs, settings, telemetry snapshot).
# Creates a timestamped .tar.gz on the Desktop (or path given as first argument).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST_PARENT="${1:-$HOME/Desktop}"
BUNDLE_NAME="DroneHubGCS-support-${STAMP}"
OUT="${DEST_PARENT}/${BUNDLE_NAME}"

CONFIG_DIR="${HOME}/.config/dronehub.ge"
DATA_DIR="${HOME}/Documents/DroneHubGCS Daily"
RELEASE_APP="${ROOT}/qgroundcontrol/build/Release/DroneHubGCS.app"

mkdir -p "${OUT}"

write_meta() {
  {
    echo "DroneHub GCS field support bundle"
    echo "created: $(date -Iseconds)"
    echo "host: $(uname -a)"
    sw_vers 2>/dev/null || true
    echo "bundle_script: tools/export-field-logs.sh"
    if [[ -x "${RELEASE_APP}/Contents/MacOS/DroneHubGCS" ]]; then
      echo "app_bundle: ${RELEASE_APP}"
      strings "${RELEASE_APP}/Contents/MacOS/DroneHubGCS" 2>/dev/null | rg -m1 "Stable_V5|DroneHub" || true
    fi
  } > "${OUT}/README.txt"
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    cp -R "$src" "$dst"
  fi
}

write_meta

copy_if_exists "${CONFIG_DIR}" "${OUT}/config-qsettings"
copy_if_exists "${DATA_DIR}/Logs" "${OUT}/Logs"
copy_if_exists "${DATA_DIR}/CrashLogs" "${OUT}/CrashLogs"
copy_if_exists "${DATA_DIR}/MavlinkActions" "${OUT}/MavlinkActions"
copy_if_exists "${DATA_DIR}/Parameters" "${OUT}/Parameters"

if [[ -d "${DATA_DIR}/Telemetry" ]]; then
  mkdir -p "${OUT}/Telemetry-recent"
  # Keep bundle small — last 10 telemetry files only.
  find "${DATA_DIR}/Telemetry" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -10 \
    | while IFS= read -r f; do
        cp "$f" "${OUT}/Telemetry-recent/"
      done
fi

ARCHIVE="${DEST_PARENT}/${BUNDLE_NAME}.tar.gz"
tar -czf "${ARCHIVE}" -C "${DEST_PARENT}" "${BUNDLE_NAME}"
rm -rf "${OUT}"

echo "Support bundle: ${ARCHIVE}"
echo "Share this archive when reporting field issues."
