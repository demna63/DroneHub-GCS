# AGENTS.md

DroneHub GCS is a **custom build of QGroundControl** (Qt 6 / QML drone Ground Control
Station), with Georgian localization and DroneHub branding. This repo is **not** a
self-contained app — it is an overlay (`custom/` + `translations/`) that is injected into
an upstream QGroundControl source tree.

For project strategy, layering, and roadmap see `README.md` and `CLAUDE.md`. For the
standard build commands see `README.md` §4 / `.github/workflows/build.yml`.

## Cursor Cloud specific instructions

### Environment layout (already provisioned in the VM snapshot)
- **Qt 6.8.3** (desktop, gcc_64) is installed at `~/Qt/6.8.3/gcc_64` via `aqtinstall`.
  Pass it to CMake with `-DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/gcc_64"`.
- The upstream QGC tree lives at `qgroundcontrol/` (git-ignored, cloned by `bootstrap.sh`,
  tag `Stable_V5.0`). `custom/` and `translations/qgc_ka.ts` are **symlinked** into it, so
  edits to `custom/` are reflected immediately with no re-wiring needed.
- The Georgian font `custom/res/fonts/NotoSansGeorgian.ttf` is git-ignored; the update
  script fetches it. Without it the build still works but Georgian glyphs render as boxes.

### Qt version (canonical)
- **Qt 6.8.3 LTS** is the project pin — matches upstream `Stable_V5.0`, all CI workflows,
  and local macOS field tests. Stay on 6.8.3 until upstream QGC validates a newer LTS/stable
  release and DroneHub CI/QA pass on it. Do not use 6.10.x ad-hoc.

### Build / run (after the update script has run)
```bash
cd qgroundcontrol
cmake -S . -B build -G Ninja \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/gcc_64" \
  -DCMAKE_BUILD_TYPE=Release \
  -DQGC_CUSTOM_BUILD=ON \
  -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF
cmake --build build            # ~8 min on 4 cores; binary: build/Release/DroneHubGCS
```
- `QGC_ENABLE_GST_VIDEOSTREAMING=OFF` matches CI and avoids GStreamer video deps; the
  custom plugin/branding/QML is what gets verified.
- CMake configure pulls most third-party deps via FetchContent (needs network on first run);
  QGC uses only one git submodule (`ArduPilot-Parameter-Repository`).

### Running the GUI (headless VM)
- A display is available at `DISPLAY=:1`. Run with software rendering (no GPU):
  ```bash
  cd qgroundcontrol/build/Release
  DISPLAY=:1 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software ./DroneHubGCS
  ```
- Confirmation the custom plugin loaded: the log prints
  `Georgian font registered: "Noto Sans Georgian" (DroneHub.CustomPlugin)` and settings go
  to `~/.config/DroneHub Georgia/DroneHubGCS Daily.ini`.
- Benign warnings to ignore on this VM: `pipewire-0.3` not loaded, `speechd` text-to-speech
  plugin failing, `propagateSizeHints()` unsupported.
- No drone hardware is needed to exercise core functionality: use **Plan view** to build an
  offline mission (the custom plugin defaults offline plans to PX4 / MultiRotor). Select the
  Waypoint tool, then click the map to drop numbered waypoints.

### Lint / tests
- There is **no unit-test suite or linter** in this repo. "Testing" == cross-platform
  compile/link verification (the CMake build above, plus `.github/workflows/build.yml` for
  Linux/Windows/macOS). Full runtime QA requires real drone hardware (field test).

### Toolchain gotcha
- The unversioned `c++`/`g++` driver selects the newest installed GCC (14), so
  `libstdc++-14-dev` must be present or CMake's compiler check fails with
  `cannot find -lstdc++`. It is installed in this environment.
