# Releasing DroneHub GCS

The release pipeline builds signed desktop installers for all three platforms and
publishes them to a GitHub Release.

## Cut a release

1. Update `CHANGELOG.md`: move items from `## [Unreleased]` into a new
   `## [X.Y.Z] - YYYY-MM-DD` section (this exact heading is what the workflow reads).
2. Commit on `master`.
3. Tag and push:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

`.github/workflows/release.yml` then:
- calls `build.yml` (reusable) with `include_macos: true` and `sign: true`,
- builds `.dmg` (macOS), NSIS `.exe` (Windows), `.AppImage` (Linux) via CPack,
- signs/notarizes if the signing secrets exist,
- creates the GitHub Release using the matching `CHANGELOG.md` section as notes,
- attaches the installers.

Pre-release tags (containing `-`, e.g. `v1.0.0-rc1`) are marked as prereleases.

> ⚠️ Release builds run macOS (10× Actions-minute cost). This is intentional and
> infrequent. Day-to-day `build.yml` runs stay Linux + Windows only.

## Versioning

Semantic Versioning (`vMAJOR.MINOR.PATCH`). The tag is the source of truth for the
release name and the CHANGELOG lookup.

## Signing secrets (optional but required for distributable installers)

Without these, the pipeline still publishes **unsigned** installers (macOS shows
"unidentified developer"; Windows shows SmartScreen). Add them under
**Settings → Secrets and variables → Actions** to activate signing automatically.

### macOS (Developer ID Application + notarization)

| Secret | What it is |
|---|---|
| `MACOS_CERT_P12` | base64 of your Developer ID `.p12` (`base64 -i cert.p12`) |
| `MACOS_CERT_PASSWORD` | password for the `.p12` |
| `MACOS_SIGN_IDENTITY` | e.g. `Developer ID Application: Name (TEAMID)` |
| `MACOS_NOTARY_APPLE_ID` | Apple ID email used for notarization |
| `MACOS_NOTARY_TEAM_ID` | 10-char Apple Team ID |
| `MACOS_NOTARY_PASSWORD` | app-specific password for that Apple ID |

### Windows (Authenticode)

| Secret | What it is |
|---|---|
| `WINDOWS_CERT_PFX` | base64 of your code-signing `.pfx` |
| `WINDOWS_CERT_PASSWORD` | password for the `.pfx` |

The signing steps are gated on both `sign: true` **and** the relevant secret being
present, so the workflow stays green before certificates are provisioned.

## What the release includes

- **Desktop** installers (`.dmg` / `.exe` / `.AppImage`) — signed if secrets present.
- **Android** APK — currently **unsigned** (see follow-up below).
- **WASM** experimental bundle — **opt-in only** via the `include_wasm` dispatch input
  (never built on a plain tag push); attached as `DroneHubGCS-WASM-experimental.zip`.

## Follow-ups not yet wired into the release

- Android APK **signing** (`android.yml` builds with `QT_ANDROID_SIGN_APK=OFF`; needs a
  keystore + `ANDROID_KEYSTORE*` secrets and `QT_ANDROID_SIGN_APK=ON`).
- Hardware field test sign-off before a public (non-prerelease) tag.
