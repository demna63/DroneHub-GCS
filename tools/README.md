# DroneHub GCS — developer tools

## Translation pipeline (F4)

| Script / doc | Purpose |
|--------------|---------|
| `qgc-lupdate.sh` | Extract new/changed strings from `custom/` into `translations/qgc_ka.ts` |
| `apply-ka-batch2.py` | Apply curated Georgian UI translations (safe chrome only) |
| `CROWDIN.md` | Crowdin project setup, CLI sync, GitHub Action secrets |

### Adding user-facing strings

1. Use `qsTr()` in QML and `tr()` in C++ — never hardcode Georgian in source.
2. Run `./tools/qgc-lupdate.sh` after adding strings.
3. Translate in **Crowdin** (preferred for bulk work), Qt Linguist, or `apply-ka-batch2.py` for curated batches.
4. Open a PR; `.github/workflows/translations.yml` runs lupdate when `custom/**` or `translations/**` change.

### Crowdin (remaining ~2877 strings)

1. `./tools/qgc-lupdate.sh` — refresh `translations/qgc_ka.ts`
2. Follow **`tools/CROWDIN.md`** — create project, `crowdin upload sources`, translator workflow, `crowdin download` or CI PR
3. Root config: `crowdin.yml` · CI: `.github/workflows/crowdin.yml` (needs `CROWDIN_PROJECT_ID` + `CROWDIN_PERSONAL_TOKEN` secrets)

**Safety rule:** flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…) stay English.
