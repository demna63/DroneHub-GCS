# DroneHub GCS — developer tools

## Translation pipeline (F4)

| Script / doc | Purpose |
|--------------|---------|
| `run-dhgcs.sh` | Open the canonical Release `DroneHubGCS.app` (avoids stale bundles) |
| `rebuild-dhgcs.sh` | Rebuild Release target (`--open` to launch after build) |
| `start-sitl-session.sh` | **GCS first** → wait UDP 14550 → PX4 (`none_iris` default) or simulator |
| `connect-checklist.sh` | Alias → `start-sitl-session.sh` |
| `field-test.sh` | Alias → `start-sitl-session.sh` |
| `px4-install-deps.sh` | Install PX4 Python deps on the correct interpreter (3.11) |
| `simulate-mavlink-udp.py` | Lightweight UDP simulator for HUD tests without PX4 |
| `qgc-lupdate.sh` | Extract new/changed strings from `custom/` into `translations/qgc_ka.ts` |
| `apply-ka-batch2.py` | Apply curated Georgian UI translations — batch 2 (Fly/Plan/toolbar) |
| `apply-ka-batch3.py` | Apply batch 3 (Setup/Safety/Links/Analyze chrome) |
| `apply-ka-translations.sh` | Run batch 2 + batch 3 |
| `CROWDIN.md` | Crowdin project setup, CLI sync, GitHub Action secrets |

### SITL / field test (macOS)

**Order matters:** DroneHub GCS must listen on UDP **14550** *before* PX4 or the simulator starts.
Otherwise AutoConnect never sees the vehicle.

```bash
./tools/start-sitl-session.sh              # GCS → PX4 none_iris (if built)
./tools/start-sitl-session.sh --simulator  # GCS → pymavlink only (no PX4)
PX4_SITL_TARGET=sihsim_quadx ./tools/start-sitl-session.sh --px4  # built-in physics sim
```

Set `PX4_DIR` if PX4 is not at `~/Desktop/PX4-Autopilot`. Stop stale sessions with
`killall px4 DroneHubGCS` before retrying.

### Adding user-facing strings

1. Use `qsTr()` in QML and `tr()` in C++ — never hardcode Georgian in source.
2. Run `./tools/qgc-lupdate.sh` after adding strings.
3. Translate in **Crowdin** (preferred for bulk work), Qt Linguist, or `./tools/apply-ka-translations.sh` for curated batches.
4. Run `./tools/qgc-lupdate.sh` locally, or trigger **DroneHub Translations** manually in Actions.

**CI note:** All workflows are manual-only (`workflow_dispatch`) — no automatic runs on push/PR.

### Crowdin (remaining strings)

**Status (batch 3 applied):** ~2990 / 3287 entries have Georgian text. Remaining ~115 are flight-mode names (intentionally English). ~90 are acronyms/brands (GPS, KML, AMSL, GeoFence, …).

1. `./tools/qgc-lupdate.sh` — refresh `translations/qgc_ka.ts`
2. `./tools/apply-ka-translations.sh` — apply safe curated batches locally
3. Follow **`tools/CROWDIN.md`** — create project, `crowdin upload sources`, translator workflow, `crowdin download` or manual Crowdin sync workflow
4. Root config: `crowdin.yml` · CI: `.github/workflows/crowdin.yml` (manual; needs `CROWDIN_PROJECT_ID` + `CROWDIN_PERSONAL_TOKEN` secrets)

**Safety rule:** flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…) stay English.
