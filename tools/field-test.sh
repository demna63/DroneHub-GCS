#!/usr/bin/env bash
# DroneHub GCS — field / SITL smoke test (delegates to start-sitl-session.sh).
exec "$(cd "$(dirname "$0")" && pwd)/start-sitl-session.sh" "$@"
