# Changelog

All notable changes to DroneHub GCS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The release workflow (`.github/workflows/release.yml`) publishes the section that
matches the pushed tag (`v1.2.3` → the `## [1.2.3]` block) as the GitHub Release notes.

## [Unreleased]

## [1.0.1] - 2026-10-09

### Added
- Georgian translation of JSON-sourced strings (`translations/qgc_json_ka.ts`, 1821 messages):
  Settings labels/descriptions, Fact metadata, mission-command parameter fields, camera/survey settings.

### Fixed
- Release workflow: build/android/wasm no longer cancel each other (unique concurrency groups).
- macOS DMG built via `cmake --install` and uploaded with the release.

## [1.0.0] - 2026-10-08

QGroundControl **v5.1.5** / Qt **6.11.1** migration (Stage 1).

### Changed
- Engine base QGC `Stable_V5.0` / Qt 6.8.3 → **v5.1.5 / Qt 6.11.1**; QML overrides retargeted to
  the 5.1 module layout (`FlyView`, `Toolbar`, `MainWindow`, `AppSettings`), patches rebased.
- Settings → Telemetry: DHGM group is now a generated settings component (`AppSettings-dhgm-telemetry.patch`).
- Fresh installs start in Georgian regardless of the OS locale (an explicit "System" choice is kept).
- App version pinned to 1.0.0 everywhere (About, `qgc_version.h`, installer/package names).

### Fixed
- Shutdown crash (URL interceptor now removed in `destroyQmlApplicationEngine`).
- `‹ Exit <tool>` navigation back to the map from Settings/Setup.
- Slide-to-confirm track invisible in the 5.1 toolbar; Space hold-to-confirm focus.
- MAVLink action confirm dialog (custom override registered; `SliderSwitch.reset()`).
- macOS app icon, Android launcher icons.

### CI
- Windows NSIS installer, Linux `.deb`, installable Android APK (test-key signed until a release
  keystore is configured).
- Qt 6.11.1 via aqtinstall pinned to a master commit (PyPI 3.3.0 can't read the Qt 6.11 Windows repo);
  Android Qt host `all_os`; Georgian catalog (`qgc_source_ka`) shipped on every platform.
- Desktop installer artifacts (.dmg / .exe / .deb) uploaded by the build workflow; tag-triggered
  release pipeline; opt-in code signing / notarization (see `docs/RELEASE.md`).

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
