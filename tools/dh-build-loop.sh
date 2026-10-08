#!/bin/zsh
# DroneHub GCS 5.1 — build/run loop driven by a trigger file.
# Usage: ./tools/dh-build-loop.sh   (Ctrl+C to stop)
#   echo build > qgroundcontrol/build/dh-loop/trigger   -> incremental build
#   echo run   > qgroundcontrol/build/dh-loop/trigger   -> (re)launch app, log to app.log
#   echo stop  > qgroundcontrol/build/dh-loop/trigger   -> quit loop
set -u
ROOT="${0:A:h:h}"
BUILD="$ROOT/qgroundcontrol/build"
LOOP="$BUILD/dh-loop"
mkdir -p "$LOOP"
export PATH="$(brew --prefix python@3.12)/libexec/bin:$PATH"
NCPU=$(sysctl -n hw.ncpu)
APP_PID=""

do_build() {
  echo "running" > "$LOOP/status"
  cmake --build "$BUILD" -j"$NCPU" > "$LOOP/build.log" 2>&1
  local rc=$?
  echo "build rc=$rc $(date +%T)" > "$LOOP/status"
  echo "[$(date +%T)] build rc=$rc"
}

do_run() {
  [[ -n "$APP_PID" ]] && kill "$APP_PID" 2>/dev/null
  pkill -x DroneHubGCS 2>/dev/null; sleep 1
  local bin=$(ls -d "$BUILD"/Release/DroneHubGCS.app/Contents/MacOS/DroneHubGCS "$BUILD"/DroneHubGCS.app/Contents/MacOS/DroneHubGCS 2>/dev/null | head -1)
  if [[ -z "$bin" ]]; then echo "run: app not found" > "$LOOP/status"; return; fi
  QT_LOGGING_RULES="qt.qml.*=true" "$bin" > "$LOOP/app.log" 2>&1 &
  APP_PID=$!
  echo "running app pid=$APP_PID $(date +%T)" > "$LOOP/status"
  echo "[$(date +%T)] app started ($APP_PID)"
}

echo build > "$LOOP/trigger"
last=""
echo "dh-build-loop: watching $LOOP/trigger"
while true; do
  cur=$(stat -f %m "$LOOP/trigger" 2>/dev/null)
  if [[ "$cur" != "$last" ]]; then
    last="$cur"
    case "$(cat "$LOOP/trigger")" in
      build) do_build ;;
      run)   do_run ;;
      buildrun) do_build; grep -q "rc=0" "$LOOP/status" && do_run ;;
      stop)  echo "stopped" > "$LOOP/status"; exit 0 ;;
    esac
  fi
  sleep 2
done
