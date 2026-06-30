# CLAUDE.md — DroneHub GCS

> Place this file at the root of the `DroneHub-GCS/` repo (next to the `qgroundcontrol/` folder).

## რა არის ეს პროექტი
Desktop **Ground Control Station** (DroneHubGCS) — **QGroundControl-ის fork**.
Bundle ID: `org.dronehub.GCS`. macOS build output:
`DroneHub-GCS/qgroundcontrol/build/Release/DroneHubGCS.app`.
დანიშნულება: PX4 (და სავარაუდოდ ArduPilot) დრონების მართვა, mission planning, telemetry, parameter tuning.

## სტეკი
- **Qt 6.8.3** (QML + C++) — QGC Stable_V5.0-ის სტეკი (6.6.3 = minimum ძველ პლატფორმებზე; canonical pin = 6.8.3, იხ. CI `QT_VERSION`)
- **QGC base:** upstream `Stable_V5.0` (CI `QGC_TAG`)
- **CMake** + **Ninja** build system
- **MAVLink** — QGC-ის ნაგულისხმევი dialect (common + ardupilotmega + PX4/development; ცალკე `MAVLINK_DIALECT` არ ვაყენებთ)
- QML — UI ფენა; C++ — backend/business logic

## Build & Run
> ⚠️ **`qgroundcontrol/` (ძრავა) gitignore-შია ამ repo-ში** — ცალკე იკლონება (`Stable_V5.0`).
> ამ repo-დან ერთვის `custom/` + `translations/`; QGC core ავტომატურად პოულობს `custom/`-ს
> (`add_subdirectory(custom)`). Configure-ზე patch-ები ავტომატურად ისმება
> (`tools/apply-qgc-patches.sh`) და custom QML ისინქრონდება core-ის წყაროებში.

```bash
# Configure (macOS, Qt 6.8.3 prefix path-ით)
cmake -S qgroundcontrol -B qgroundcontrol/build -G Ninja \
  -DCMAKE_PREFIX_PATH="<Qt 6.8.3 prefix>" -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build qgroundcontrol/build -j$(sysctl -n hw.ncpu)

# Output (macOS — Finder-ში ჩანს build/DroneHubGCS.app → Release symlink)
open qgroundcontrol/build/Release/DroneHubGCS.app
```
რეალური multi-platform build (Linux/Windows/Android/WASM): `.github/workflows/`
(`build.yml`, `android.yml`, `wasm.yml`) — კლონავს QGC-ს + wire-ავს `custom/`-ს.

## არქიტექტურა — "no hard-fork" (სად რა დევს)
**ყველა ჩვენი ცვლილება `custom/`-შია** (tracked); `qgroundcontrol/` (engine) gitignore-შია და უცვლელია.
core QGC ფაილს პირდაპირ **არ** ვცვლით — სამი მექანიზმით ვმუშაობთ:

1. **`custom/src/`** — `CustomPlugin` (QGCCorePlugin subclass) + `CustomOptions`. აქ ხდება defaults,
   settings-enum თარგმანი (`adjustSettingMetaData`), palette, locale, font, brand.
2. **custom QML override** (`custom/res/Custom/qml/...`) — ცვლის core QML-ს file-sync-ით
   (`custom/CMakeLists.txt`: `DRONEHUB_*_SRC|DST` → core წყაროებში კოპირდება build-/configure-დროს).
   qmlcache-registered ფაილი **configure-time `foreach`-შიც** უნდა იყოს (და build target-შიც).
3. **patch** (`custom/patches/*.patch`) — surgical C++/CMake ცვლილებები core-ში; იდემპოტენტურად
   ისმება `tools/apply-qgc-patches.sh`-ით (glob, configure-დროს). დიდ ცვლილებას = QML override,
   პატარა/ქირურგიულს = patch.

ხარისხის კონტროლი: `tools/check-qml-override-drift.py` — ადევნებს თვალს override↔upstream drift-ს.

**Engine code (qgroundcontrol/, reference-only):** `src/Vehicle`, `src/Comms` (MAVLink),
`src/MissionManager`, `src/FactSystem` (params), `src/FirmwarePlugin/{PX4,APM}`, `*.qml` UI.

⚠️ upstream rebase-ის ტვირთი: რაც მეტი QML სრულად vendor-დება, მით მეტი merge-ი — patch უმჯობესია სადაც შესაძლებელია.

## კონვენციები
- C++: QGC-ის არსებულ სტილს მიჰყევი (Qt naming, `m_` prefix member-ებზე)
- QML: არსებული component-ების reuse, არა ნულიდან წერა
- ცვლილებამდე შეამოწმე ხომ არ აკეთებს QGC-ი იმავეს უკვე

## დომენური კონტექსტი
- PX4 + ArduPilot ორივე მუშაობს (APM plugin compiled-in); PX4 = offline-plan default.
- PX4 parameter conventions, flight modes, MAVLink command set ცნობილია — ბაზისური ახსნა არ მჭირდება.

## რა შეიცვალა upstream-თან შედარებით (DroneHub mods)
**Branding:** app name `DroneHubGCS`, bundle id `org.dronehub.GCS` (macOS) / `org.dronehub.gcs`
(Android applicationId), org `DroneHub Georgia` / `dronehub.ge`, copyright; macOS `.icns`,
Windows `.ico`, Android launcher icons (ყველა density); DroneHub logo/splash/video-placeholder;
pinned version **1.0.0** (`custom/CMakeLists.txt`, PARENT_SCOPE — engine-git-independent).

**ქართული ლოკალიზაცია (სრული):** `translations/qgc_ka.ts` (~4300 string); Noto Sans Georgian + `ka` locale;
settings enums → `CustomPlugin::adjustSettingMetaData`; **ყველა** fact/param enum →
`FactMetaData-enum-tr.patch` (`setEnumInfo`/`setBitmaskInfo` → "FactEnum" ts-context, PX4 param
metadata-საც ფარავს); mission command names → `MissionCommand-friendlyName-tr.patch` ("MissionCommands"
context, 87 სახელი); flight-mode menu → custom `FlightModeIndicator.qml` (Georgian display-map,
დინამიური PX4 v1.14+ რეჟიმებიც).

**Fly view UI:** DroneHub `Theme` (მუქი palette); `FlyViewCustomLayer` — კონფიგურირებადი HUD
(compact + expanded metrics); custom toolbar (logo, indicators, mission clock, video-status);
video PiP ყოველთვის-ჩართული + GStreamer (`disableWhenDisarmed=false`, UDP h264 default);
tool strip — Analyze ყოველთვის, Viewer3D default-on.

**Plan view restyle (HUD-style):** ფართო editor panel + glass chrome (`PlanView-panel-*.patch`);
custom `MissionItemEditor`/`SimpleItemEditor`/`MissionSettingsEditor` (დიდი ფონტი, spacing).

**ქცევა/defaults:** PX4 multirotor offline default; Brand Image settings დამალული; multi-vehicle
list = base default. **dronehub.ge backend ინტეგრაცია — ჯერ არ არსებობს (TODO, თუ დაგეგმილია).**

**პლატფორმები/CI:** macOS · Windows (MSVC) · Linux · Android (arm64) · WASM — GitHub Actions-ით.

## სამუშაო წესი
- კოდი ჯერ, ახსნა მერე; ახსნა მოკლე
- დიდი ცვლილებამდე გეგმა დამიდასტურე
- დაშვებებს ხმამაღლა ვაცხადებ
