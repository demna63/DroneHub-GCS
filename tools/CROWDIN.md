# Crowdin — Georgian (`ka`) translations

DroneHub GCS keeps one canonical Qt TS file: `translations/qgc_ka.ts` (~3267 strings, English source → Georgian target). Crowdin is the recommended path for the remaining ~2877 unfinished strings.

**Safety rule (do not translate in Crowdin):** flight-mode names and attitude axes (Roll, Pitch, Yaw, Loiter, …) stay English. See `apply-ka-batch2.py` `SKIP_SOURCES` / `SKIP_CONTEXT_RE`.

## Prerequisites

- [Crowdin CLI](https://crowdin.github.io/crowdin-cli/installation) (`crowdin` on `PATH`)
- Fresh strings from `./tools/qgc-lupdate.sh` (or manual CI **DroneHub Translations** artifact)
- Crowdin account with permission to create/manage a project


## Fresh setup (credentials rotation)

Use this when rotating tokens or setting up a new machine. DroneHub project ID: **909155**.

1. **Revoke old tokens:** [crowdin.com](https://crowdin.com/) → **Account Settings** → **API** → revoke unused Personal Access Tokens.
2. **Create a new token** with at least **Projects → Read, Write** (not an OAuth app secret).
3. **Local shell** — either run the helper script (recommended) or add to `~/.zshrc`:
   ```bash
   export CROWDIN_PROJECT_ID="909155"
   export CROWDIN_PERSONAL_TOKEN="<personal-access-token>"
   ```
4. **GitHub Actions** — repository secrets on `demna63/DroneHub-GCS`:
   ```bash
   gh secret set CROWDIN_PROJECT_ID --body "909155" --repo demna63/DroneHub-GCS
   gh secret set CROWDIN_PERSONAL_TOKEN --body "<personal-access-token>" --repo demna63/DroneHub-GCS
   ```
   Or one step from repo root (sets both GitHub secret and `~/.zshrc`, then runs `crowdin status`):
   ```bash
   ./tools/crowdin-setup-secrets.sh "<personal-access-token>"
   ```
5. Verify: `crowdin info` or `crowdin status` from the repo root (requires `CROWDIN_*` env vars).

## 1. Create the Crowdin project

1. Go to [crowdin.com](https://crowdin.com/) → **Create project**.
2. **Source language:** English.
3. **Target language:** Georgian (`ka`).
4. **File format:** Qt TS (`.ts`) — usually auto-detected on first upload.
5. Note the **Project ID**: Project → **Tools** → **API** → Project ID.

## Troubleshooting CI auth

If **DroneHub Crowdin Sync** fails with `Couldn't authorize. Check your 'api_token'`:

1. Regenerate a **Personal Access Token** at [crowdin.com](https://crowdin.com/) → **Account Settings** → **API** (not an OAuth app secret).
2. Token needs at least **Projects → Read, Write** (or **Full access** for small teams).
3. Update repository secret `CROWDIN_PERSONAL_TOKEN` (Settings → Secrets and variables → Actions).
4. Set `CROWDIN_PROJECT_ID` to the **numeric** Project ID (Project → Tools → API), with no quotes or spaces.
5. Re-run the workflow after saving secrets.

The Node.js 20 deprecation notice on `actions/checkout` is a warning only; sync failures are unrelated until Crowdin auth succeeds.

## 2. Configure credentials (local)

Export env vars (do **not** commit these):

```bash
export CROWDIN_PROJECT_ID="<numeric-project-id>"
export CROWDIN_PERSONAL_TOKEN="<personal-access-token>"   # crowdin.com → Account Settings → API
```

Optional: add to your shell profile or use a local `.env` file that is gitignored.

Verify:

```bash
crowdin info
```

## 3. Initial upload (one-time seed)

From the repo root, after `./tools/qgc-lupdate.sh`:

```bash
# Push English source strings (from <source> tags) + file structure
crowdin upload sources

# Seed Crowdin with the 390 existing Georgian translations in the repo
crowdin upload translations
```

Confirm in the Crowdin UI: `translations/qgc_ka.ts` appears with ~3267 strings and partial progress.

## 4. Translator workflow

1. Translators work in the Crowdin web editor (or assigned tasks).
2. Use **Build** in Crowdin when you want a downloadable snapshot (CLI/CI pulls via API).
3. Prefer consistent UI terminology with existing batch translations (see finished entries in `qgc_ka.ts`).

**Do not translate:** flight modes, Roll/Pitch/Yaw, MAVLink mode names, and other safety-critical identifiers listed in `tools/apply-ka-batch2.py`.

## 5. Download translations back to the repo

### Option A — Crowdin CLI (no GitHub secrets)

```bash
crowdin download
git diff translations/qgc_ka.ts   # review
# open PR with updated qgc_ka.ts
```

### Option B — GitHub Action (recommended for maintainers)

Add repository secrets:

| Secret | Value |
|--------|--------|
| `CROWDIN_PROJECT_ID` | Numeric project ID |
| `CROWDIN_PERSONAL_TOKEN` | Crowdin personal access token |

Workflow: `.github/workflows/crowdin.yml`

- **Manual only:** Actions → **DroneHub Crowdin Sync** → **Run workflow** (optional `ref`, default `master`)
- All GitHub Actions in this repo are manual-only (`workflow_dispatch`) to save CI billing — no push/PR/schedule triggers

If sync succeeds but PR creation fails with **403**, enable **Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.

The workflow uses `upload_translations: false` so translator edits in Crowdin are not overwritten by stale local copies. Re-run `crowdin upload translations` locally only when intentionally re-seeding Crowdin from git.

## 6. Day-to-day developer flow

```
edit custom/ (qsTr / tr)
    → ./tools/qgc-lupdate.sh
    → crowdin upload sources   (or run **DroneHub Translations** / **DroneHub Crowdin Sync** manually)
    → translators in Crowdin
    → crowdin download / Crowdin PR
    → merge PR
```

Run `./tools/qgc-lupdate.sh` locally after editing `custom/**` or `translations/**`, or trigger **DroneHub Translations** manually in Actions before uploading to Crowdin.

## 7. Validate `qgc_ka.ts` before upload

```bash
python3 -c "
import xml.etree.ElementTree as ET
r = ET.parse('translations/qgc_ka.ts').getroot()
msgs = r.findall('.//message')
unfinished = sum(1 for m in msgs if m.find('translation') is not None and m.find('translation').get('type') == 'unfinished')
done = len(msgs) - unfinished
print(f'messages={len(msgs)} finished={done} unfinished={unfinished} language={r.get(\"language\")}')
"
```

Expected: `language=ka_GE`, `sourcelanguage=en` in the file header.

## Reference

- Repo config: `crowdin.yml`
- String extraction: `tools/qgc-lupdate.sh`, `.github/workflows/translations.yml` (manual)
- Upstream QGC: [crowdin.yml](https://github.com/mavlink/qgroundcontrol/blob/master/crowdin.yml), [translations README](https://github.com/mavlink/qgroundcontrol/tree/master/translations)
