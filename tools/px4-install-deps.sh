#!/usr/bin/env bash
# Install PX4 build Python deps for the interpreter CMake actually uses.
set -euo pipefail

PX4="${PX4_DIR:-$HOME/Desktop/PX4-Autopilot}"
REQ="$PX4/Tools/setup/requirements.txt"
PY="${PX4_PYTHON:-${HOME}/.local/bin/python3.11}"

if [[ ! -f "$REQ" ]]; then
  echo "error: PX4 not found at $PX4" >&2
  echo "  clone: git clone https://github.com/PX4/PX4-Autopilot.git $PX4" >&2
  exit 1
fi

if [[ ! -x "$PY" ]]; then
  PY="$(command -v python3)"
fi

echo "==> PX4 Python deps via: $PY"
"$PY" -m pip install -r "$REQ" --break-system-packages
echo "==> Done. Build with: cd $PX4 && make px4_sitl none_iris"
