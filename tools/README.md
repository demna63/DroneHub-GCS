# DroneHub GCS — developer tools

## Translation pipeline (F4)

| Script / doc | Purpose |
|--------------|---------|
| `run-dhgcs.sh` | Open the canonical Release `DroneHubGCS.app` (avoids stale bundles) |
| `rebuild-dhgcs.sh` | Rebuild Release target (`--open` to launch after build) |
| `start-sitl-session.sh` | **GCS first** → wait UDP 14550 → PX4 (`sihsim_quadx` default, live physics) or simulator |
| `connect-checklist.sh` | Alias → `start-sitl-session.sh` |
| `field-test.sh` | Alias → `start-sitl-session.sh` |
| `px4-install-deps.sh` | Install PX4 Python deps on the correct interpreter (3.11) |
| `simulate-mavlink-udp.py` | Lightweight UDP simulator for HUD tests without PX4 |
| `qgc-lupdate.sh` | Extract new/changed strings from `custom/` into `translations/qgc_ka.ts` |
| `apply-ka-batch2.py` | Apply curated Georgian UI translations — batch 2 (Fly/Plan/toolbar) |
| `apply-ka-batch3.py` | Apply batch 3 (Setup/Safety/Links/Analyze chrome) |
| `apply-ka-batch4.py` | Apply batch 4 (HUD, MAVLink confirm UI, Phase 1/2 cleanup) |
| `apply-ka-batch5.py` | Apply batch 5 (Phase 4 health panel, Plan toolbar, operator UX) |
| `apply-ka-translations.sh` | Run batch 2 + batch 3 + batch 4 + batch 5 |
| `check-hud-tokens.py` | Verify `Theme.qml` HUD tokens match `FlyViewCustomLayer` inline `_t` |
| `check-qml-override-drift.py` | Detect drift between custom QML and qmlcache sync targets |
| `check-dronehub-stability.sh` | Run HUD token + QML drift checks (Phase 2) |
| `check-translation-stats.py` | Summary of `qgc_ka.ts` coverage (fails if unfinished remain) |
| `check-video-build.sh` | Verify GStreamer/video compile flags in local build |
| `smoke-runtime.sh` | Phase 3 smoke: stability + translations + video + optional `--live` SITL |
| `export-field-logs.sh` | Field support bundle (.tar.gz) — settings, logs, telemetry snapshot |
| `CROWDIN.md` | Crowdin project setup, CLI sync, GitHub Action secrets |

### SITL / field test (macOS)

**Order matters:** DroneHub GCS must listen on UDP **14550** *before* PX4 or the simulator starts.
Otherwise AutoConnect never sees the vehicle.

```bash
./tools/start-sitl-session.sh              # GCS → PX4 sihsim_quadx, live HUD (if built)
./tools/start-sitl-session.sh --simulator  # GCS → pymavlink only (no PX4)
PX4_SITL_TARGET=none_iris ./tools/start-sitl-session.sh --px4   # lighter no-physics link
./tools/start-sitl-session.sh -y           # skip the "stops px4/GCS" confirmation
```

The default `sihsim_quadx` uses PX4's built-in physics, so the HUD shows live altitude/speed;
`none_iris` only establishes the link (static telemetry). The session **stops any running
px4 / DroneHubGCS first** — it prompts before doing so unless `-y` / `ASSUME_YES=1`.
Set `PX4_DIR` if PX4 is not at `~/Desktop/PX4-Autopilot`.

### Adding user-facing strings

1. Use `qsTr()` in QML and `tr()` in C++ — never hardcode Georgian in source.
2. Run `./tools/qgc-lupdate.sh` after adding strings (uses full `update_translations` when `qgroundcontrol/build` exists).
3. Translate in **Crowdin** (preferred for bulk work), Qt Linguist, or `./tools/apply-ka-translations.sh` for curated batches.
4. Run `./tools/check-translation-stats.py` — must show `Unfinished: 0` before merge.
5. Run `./tools/check-dronehub-stability.sh` after HUD/QML sync changes.

**CI note:** All workflows are manual-only (`workflow_dispatch`) — no automatic runs on push/PR.

### Crowdin (remaining strings)

**Status (batch 4 applied):** ~3040 / 3300 active entries have Georgian text. Remaining ~246 are intentional English (flight modes, acronyms, brands). Run `./tools/check-translation-stats.py` for current counts.

1. `./tools/qgc-lupdate.sh` — refresh `translations/qgc_ka.ts`
2. `./tools/apply-ka-translations.sh` — apply safe curated batches locally
3. Follow **`tools/CROWDIN.md`** — create project, `crowdin upload sources`, translator workflow, `crowdin download` or manual Crowdin sync workflow
4. Root config: `crowdin.yml` · CI: `.github/workflows/crowdin.yml` (manual; needs `CROWDIN_PROJECT_ID` + `CROWDIN_PERSONAL_TOKEN` secrets)

**Safety rule:** flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…) stay English.
