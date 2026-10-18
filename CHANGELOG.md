# Changelog

All notable changes to DroneHub GCS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The release workflow (`.github/workflows/release.yml`) publishes the section that
matches the pushed tag (`v1.2.3` → the `## [1.2.3]` block) as the GitHub Release notes.

## [Unreleased]

## [1.1.1] - 2026-10-18

### Added
- Tool strip: item names show on press-and-hold on touch screens (hover on desktop). Toolbar
  brand and camera-panel buttons have tooltips and screen-reader names.
- HUD: Escape closes the telemetry card / leaves edit mode; HUD controls and metric cells expose
  screen-reader names; the telemetry card fades in and out.
- CI: `DroneHub Checks` runs on every PR and on `master` (HUD tokens, translation stats, Georgian
  terminology). A Crowdin sync that machine-translates protected strings or brings back wrong
  drone terms now fails.

### Changed
- Toolbar shows the DHG mark and "DroneHub GCS" (name hidden on phones) instead of the DGGCS artwork.
- Setup uses a wrench icon, so it no longer looks like a second Settings cog.
- Plan view on narrow (phone) screens: the editor panel takes the full width and its open/close
  tab slides it away to reveal the map; the tab is touch-sized.
- Full-screen tool titles read "გასვლა: …" (one translatable string) instead of a concatenation.
- HUD caption and compass labels never drop below 13 px.

### Fixed
- Georgian terminology: "vehicle" was translated as a car (მანქანა / ავტომობილი) in 129 strings —
  now "აპარატი"; "props" as supports, including the remove-props safety warnings — now
  "პროპელერები"; motor, throttle and bench-test strings corrected; "add metric" no longer reads
  "ლიანდაგის დამატება".
- 47 strings that stay English on purpose (Pitch/Yaw, flight modes, compass letters, …) were
  machine-translated by a Crowdin sync; restored, and the Crowdin push now keeps them.
- Guided-action confirm: the cancel ✕ has a toolbar-height touch area (was a ~0.7 em icon).
- MAVLink action confirm and slide-to-confirm hint used point sizes as pixel sizes (tiny text);
  fixed.
- "+ add metric" in the telemetry card fits its Georgian label, is touch-height and keyboard
  reachable; HUD metric pickers keep a 44 px height on phones.
- Video status "Backend" always read "Not compiled" (API removed in QGC 5.1); it now reports the
  configured video source.
- Plan item "?" badge contrast (orange on white ≈ 2.1:1 → ≈ 7.5:1).
- `tools/check-hud-tokens.py` accepts the HUD's mobile scaling, so `tools/rebuild-dhgcs.sh` no
  longer stops before building.

## [1.1.0] - 2026-10-17

### Added
- Fly View HUD keyboard navigation: the Edit button, the edit-mode "+" slot and the metric cells
  that open the telemetry card are reachable with Tab; Return/Space activates them; focused
  controls show a 2 px accent ring.
- Critical battery/GPS metrics show a red "!" badge, so the alarm no longer relies on colour alone.

### Changed
- HUD glass plates are more opaque: secondary text stays ≥ 4.5:1 contrast over a light OSM map
  (was 1.7:1); section labels get the same text outline as values.
- HUD design tokens resynced with `Custom/Theme.qml` — on desktop the large HUD values are 24 px
  (were 28 px).
- The video placeholder logo pulses three times and then rests instead of looping forever.

### Fixed
- Phones and short windows: the HUD scales with the available height, the PiP is capped, the
  telemetry card scrolls instead of running off-screen, and the ✎/✕ glyphs (missing from Android
  fonts) are SVG icons.
- Collapsed PiP no longer leaves an empty frame; the HUD re-centres.
- HUD touch targets (Edit, remove, "+") are at least 44 px; captions never drop below 12 px.
- With the telemetry card open, a tap on the map closes the card and also reaches the map.
- The app reports its real version — 1.0.1 builds still identified themselves as 1.0.0.
- Georgian: `qgc_ka.ts` realigned with the QGC 5.1 catalogue; "Logging" → "ლოგირება",
  "Heading" → "კურსი".

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
