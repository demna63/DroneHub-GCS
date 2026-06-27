#!/usr/bin/env bash
# DroneHub GCS — one-command SITL session (GCS first, then vehicle).
exec "$(cd "$(dirname "$0")" && pwd)/start-sitl-session.sh" "$@"
