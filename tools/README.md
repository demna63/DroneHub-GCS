# DroneHub GCS — developer tools

## Translation pipeline (F4)

| Script | Purpose |
|--------|---------|
| `qgc-lupdate.sh` | Extract new/changed strings from `custom/` into `translations/qgc_ka.ts` |
| `apply-ka-batch2.py` | Apply curated Georgian UI translations (safe chrome only) |

### Adding user-facing strings

1. Use `qsTr()` in QML and `tr()` in C++ — never hardcode Georgian in source.
2. Run `./tools/qgc-lupdate.sh` after adding strings.
3. Translate in Qt Linguist, Crowdin, or extend `apply-ka-batch2.py` for batch work.
4. Open a PR; `.github/workflows/translations.yml` runs lupdate when `custom/**` or `translations/**` change.

**Safety rule:** flight-mode names and attitude axes (Roll/Pitch/Yaw/Loiter/…) stay English.
