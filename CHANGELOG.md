# Changelog

All notable changes to DroneHub GCS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The release workflow (`.github/workflows/release.yml`) publishes the section that
matches the pushed tag (`v1.2.3` → the `## [1.2.3]` block) as the GitHub Release notes.

## [Unreleased]

### Added
- Desktop installer artifacts (.dmg / .exe / .AppImage) uploaded by the build workflow.
- Tag-triggered release pipeline that publishes signed installers to GitHub Releases.
- Opt-in code signing / notarization for macOS and Windows (activates when signing
  secrets are present — see `docs/RELEASE.md`).

## [0.1.0] - 2026-06-28

First internal milestone — DroneHub GCS custom build of QGroundControl (Qt 6.8.3).

### Added
- DroneHub branding/theme (`QGCCorePlugin` subclass, palette override, Georgian font + locale).
- Fly View HUD overlay (altitude / speed / vertical / distance / satellites / battery).
- Plan View defaults (offline plan = PX4 / MultiRotor) via sanctioned custom levers.
- Setup/Params Georgian translation pipeline (lupdate + Crowdin sync; ~2990 UI strings).
- CI: desktop (Linux/Windows/macOS), Android, WASM, translation extraction, weekly Crowdin sync.
- Developer tooling: GCS-first SITL session, MAVLink simulator, rebuild/run helpers.

### Notes
- Flight-mode names and attitude axes intentionally remain English.
- macOS desktop CI is opt-in (10× Actions-minute cost).
