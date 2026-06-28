#!/usr/bin/env bash
# One DroneHubGCS.app: clean cruft, register LaunchServices, Desktop Finder alias.
set -euo pipefail

BUILD_DIR="${1:?usage: sync-dhgcs-app.sh <qgroundcontrol/build>}"
QGC_DIR="$(cd "$BUILD_DIR/.." && pwd)"
RELEASE_APP="$BUILD_DIR/Release/DroneHubGCS.app"
CANONICAL="$BUILD_DIR/DroneHubGCS.app"
LEGACY="$BUILD_DIR/DroneHubGCS_App.app"
REPO_ROOT="$(cd "$QGC_DIR/.." && pwd)"
ROOT_APP="$REPO_ROOT/DroneHubGCS.app"
DESKTOP_APP="${HOME}/Desktop/DroneHubGCS.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# Wrong-cwd artifact: cmake run inside qgroundcontrol/ created an empty duplicate bundle.
NESTED_CRUFT="$QGC_DIR/qgroundcontrol"
BROKEN_BUNDLE="$NESTED_CRUFT/build/DroneHubGCS.app"

if [[ ! -d "$RELEASE_APP" ]]; then
  echo "sync-dhgcs-app: Release bundle missing, skipping: $RELEASE_APP" >&2
  exit 0
fi

# --- remove empty / duplicate bundles ----------------------------------------
if [[ -d "$BROKEN_BUNDLE" ]]; then
  if [[ ! -f "$BROKEN_BUNDLE/Contents/MacOS/DroneHubGCS" ]]; then
    echo "sync-dhgcs-app: removing broken bundle $BROKEN_BUNDLE"
    rm -rf "$BROKEN_BUNDLE"
  fi
fi
if [[ -d "$NESTED_CRUFT" ]] && [[ -z "$(find "$NESTED_CRUFT" -mindepth 1 -maxdepth 3 -type f 2>/dev/null | head -1)" ]]; then
  echo "sync-dhgcs-app: removing empty nested dir $NESTED_CRUFT"
  rm -rf "$NESTED_CRUFT"
fi
if [[ -e "$LEGACY" ]]; then
  rm -rf "$LEGACY"
fi

# --- build/DroneHubGCS.app → Release (for scripts / relative paths) ----------
if [[ -e "$CANONICAL" || -L "$CANONICAL" ]]; then
  rm -rf "$CANONICAL"
fi
ln -s "Release/DroneHubGCS.app" "$CANONICAL"

# --- repo root shortcut ------------------------------------------------------
if [[ -e "$ROOT_APP" || -L "$ROOT_APP" ]]; then
  rm -rf "$ROOT_APP"
fi
ln -s "qgroundcontrol/build/Release/DroneHubGCS.app" "$ROOT_APP"

# --- codesign + LaunchServices (only the real Release bundle) ----------------
codesign --force --deep -s - "$RELEASE_APP" >/dev/null 2>&1 || true

if [[ -x "$LSREGISTER" ]]; then
  if [[ -d "$BROKEN_BUNDLE" ]]; then
    "$LSREGISTER" -u "$BROKEN_BUNDLE" 2>/dev/null || true
  fi
  # Unregister stale symlink paths if they were registered as bundles.
  for stale in "$CANONICAL" "$DESKTOP_APP"; do
    if [[ -L "$stale" ]]; then
      "$LSREGISTER" -u "$stale" 2>/dev/null || true
    fi
  done
  "$LSREGISTER" -f "$RELEASE_APP"
fi

# --- Desktop: Finder alias (not symlink — LaunchServices resolves reliably) ----
rm -rf "$DESKTOP_APP"
osascript <<EOF
tell application "Finder"
    set targetApp to POSIX file "$RELEASE_APP"
    set desktopFolder to desktop
    set aliasFile to make new alias file at desktopFolder to targetApp
    set name of aliasFile to "DroneHubGCS.app"
end tell
EOF

echo "sync-dhgcs-app: open from Desktop:"
echo "  $DESKTOP_APP"
