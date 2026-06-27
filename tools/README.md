# DroneHub GCS — developer tools

## Translation pipeline (F4)

| Script / doc | Purpose |
|--------------|---------|
| `run-dhgcs.sh` | Open the canonical Release `DroneHubGCS.app` (avoids stale bundles) |
| `rebuild-dhgcs.sh` | Rebuild Release target (`--open` to launch after build) |
| `field-test.sh` | Launch GCS + field-test checklist (prints absolute paths) |
| `connect-checklist.sh` | GCS-first connection steps + troubleshooting |
| `px4-install-deps.sh` | Install PX4 Python deps on the correct interpreter (3.11) |
| `simulate-mavlink-udp.py` | Lightweight UDP simulator for HUD tests without PX4 |
| `qgc-lupdate.sh` | Extract new/changed strings from `custom/` into `translations/qgc_ka.ts` |
| `apply-ka-batch2.py` | Apply curated Georgian UI translations (safe chrome only) |
| `CROWDIN.md` | Crowdin project setup, CLI sync, GitHub Action secrets |

### Adding user-facing strings

1. Use `qsTr()` in QML and `tr()` in C++ — never hardcode Georgian in source.
2. Run `./tools/qgc-lupdate.sh` after adding strings.
3. Translate in **Crowdin** (preferred for bulk work), Qt Linguist, or `apply-ka-batch2.py` for curated batches.
4. Run `./tools/qgc-lupdate.sh` locally, or trigger **DroneHub Translations** manually in Actions.

**CI note:** All workflows are manual-only (`workflow_dispatch`) — no automatic runs on push/PR.

### Crowdin (remaining ~2877 strings)

1. `./tools/qgc-lupdate.sh` — refresh `translations/qgc_ka.ts`
2. Follow **`tools/CROWDIN.md`** — create project, `crowdin upload sources`, translator workflow, `crowdin download` or manual Crowdin sync workflow
3. Root config: `crowdin.yml` · CI: `.github/workflows/crowdin.yml` (manual; needs `CROWDIN_PROJECT_ID` + `CROWDIN_PERSONAL_TOKEN` secrets)

**Safety rule:** flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…) stay English.
