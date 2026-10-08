# CLAUDE.md — DroneHub GCS

> Place this file at the root of the `DroneHub-GCS/` repo (next to the `qgroundcontrol/` folder).

## რა არის ეს პროექტი
Desktop **Ground Control Station** (DroneHubGCS) — **QGroundControl-ის fork**.
Bundle ID: `org.dronehub.GCS`. macOS build output:
`DroneHub-GCS/qgroundcontrol/build/Release/DroneHubGCS.app`.
დანიშნულება: PX4 (და სავარაუდოდ ArduPilot) დრონების მართვა, mission planning, telemetry, parameter tuning.

## სტეკი
- **Qt 6.11.1** (QML + C++) — QGC v5.1.x-ის სტეკი (minimum 6.11.0; canonical pin = 6.11.1, იხ. CI `QT_VERSION` / upstream `.github/build-config.json`)
- **QGC base:** upstream tag `v5.1.5` (CI `QGC_TAG`)
- **CMake ≥ 3.25** + **Ninja**; Python ≥ 3.10 (QGC ქმნის `qgroundcontrol/.venv`-ს); GStreamer **1.28.4** (macOS framework)
- **MAVLink** — QGC-ის ნაგულისხმევი dialect (common + ardupilotmega + PX4/development; ცალკე `MAVLINK_DIALECT` არ ვაყენებთ)
- QML — UI ფენა; C++ — backend/business logic

## Build & Run
> ⚠️ **`qgroundcontrol/` (ძრავა) gitignore-შია ამ repo-ში** — ცალკე იკლონება (`v5.1.5`).
> ამ repo-დან ერთვის `custom/` + `translations/`; QGC core ავტომატურად პოულობს `custom/`-ს
> (`add_subdirectory(custom)`). Configure-ზე patch-ები ავტომატურად ისმება
> (`tools/apply-qgc-patches.sh`) და custom QML ისინქრონდება core-ის წყაროებში.

```bash
# Configure (macOS, Qt 6.11.1; arm64-only — universal build -Werror-ზე ჩავარდება)
cmake -S qgroundcontrol -B qgroundcontrol/build -G Ninja \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.11.1/macos" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64

# Build
cmake --build qgroundcontrol/build -j$(sysctl -n hw.ncpu)

# Output (macOS — Finder-ში ჩანს build/DroneHubGCS.app → Release symlink)
open qgroundcontrol/build/Release/DroneHubGCS.app

# ლოკალური build/run loop (trigger-ფაილით მართვადი): ./tools/dh-build-loop.sh
```
`custom/res/fonts/NotoSansGeorgian.ttf` gitignore-შია — ახალ checkout-ში ხელით ჩადე (ან `tools/fetch-georgian-font.sh`).
რეალური multi-platform build (Linux/Windows/Android/WASM): `.github/workflows/`
(`build.yml`, `android.yml`, `wasm.yml`) — კლონავს QGC-ს + wire-ავს `custom/`-ს. ⚠️ WASM: QGC 5.1 upstream-ს აღარ აქვს — ექსპერიმენტული, opt-in.

## არქიტექტურა — "no hard-fork" (სად რა დევს)
**ყველა ჩვენი ცვლილება `custom/`-შია** (tracked); `qgroundcontrol/` (engine) gitignore-შია და უცვლელია.
core QGC ფაილს პირდაპირ **არ** ვცვლით — სამი მექანიზმით ვმუშაობთ:

1. **`custom/src/`** — `CustomPlugin` (QGCCorePlugin subclass) + `CustomOptions` + DHGM ინტეგრაცია
   (`CotForwarder`, `DhgmSettings`) + `CustomOsmAutoLoader`. აქ ხდება defaults,
   settings-enum თარგმანი (`adjustSettingMetaData`), palette, locale, font, brand.
2. **custom QML override** (`custom/res/Custom/qml/...`) — ცვლის core QML-ს file-sync-ით
   (`custom/CMakeLists.txt`: `DRONEHUB_*_SRC|DST` → core წყაროებში კოპირდება build-/configure-დროს).
   configure-time sync ავტომატურია (ყველა `DRONEHUB_*_SRC/_DST` წყვილი; `custom/` `src/`-მდე კონფიგურირდება).
   ⚠️ override-ს `CustomOverrideInterceptor` `qrc:/Custom/qml/...`-დან ემსახურება → same-directory
   ტიპები implicit-ად არ ჩანს: ფაილში **საკუთარი მოდულის import** აუცილებელია
   (`import QGroundControl.FlyView` / `.Toolbar` / `.AppSettings`).
   5.1 layout: FlyView → `src/FlyView` (`QGroundControl.FlyView`), toolbar/indicator-ები → `src/Toolbar`
   (`QGroundControl.Toolbar`), Plan editor-ები → `src/PlanView`, MainWindow → `src/MainWindow`.
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
pinned version **1.0.0** (`custom/CMakeLists.txt` — PARENT_SCOPE + `qgc_version.h` ხელახლა გენერირდება, რადგან 5.1 მას `include(Git)`-ში წერს).

**ქართული ლოკალიზაცია (სრული):** `translations/qgc_ka.ts` (~5000 string, 5.1-ზე 0 unfinished; ახალი batch: `tools/apply-ka-batch-json.py`); Noto Sans Georgian + `ka` locale;
settings enums → `CustomPlugin::adjustSettingMetaData`; **ყველა** fact/param enum →
`FactMetaData-enum-tr.patch` (`setEnumInfo`/`setBitmaskInfo` → "FactEnum" ts-context, PX4 param
metadata-საც ფარავს); mission command names → `MissionCommand-friendlyName-tr.patch` ("MissionCommands"
context, 87 სახელი); flight-mode menu → custom `FlightModeIndicator.qml` (Georgian display-map,
დინამიური PX4 v1.14+ რეჟიმებიც).

**Fly view UI:** DroneHub `Theme` (მუქი palette); `FlyViewCustomLayer` — კონფიგურირებადი HUD
(compact + expanded metrics); custom toolbar (logo, indicators, mission clock, video-status);
video PiP ყოველთვის-ჩართული + GStreamer (`disableWhenDisarmed=false`, UDP h264 default);
tool strip — ლოგო toggle-ავს; ნავიგაცია (Plan/Setup/Analyze/Settings) tool strip-შია (`FlyViewToolStripActionList.qml`); Viewer3D default-on (5.1 = Metal RHI, ძველი macOS+GStreamer გამონაკლისი მოხსნილია).

**Plan view restyle (HUD-style):** ფართო editor panel + glass chrome (`PlanView-panel-*.patch`); Plan toolbar = upstream 5.1 (ძველი stats override ჩამოშორდა);
custom `MissionItemEditor`/`SimpleItemEditor`/`MissionSettingsEditor` (დიდი ფონტი, spacing).

**ქცევა/defaults:** PX4 multirotor offline default; Brand Image settings დამალული; multi-vehicle
list = base default. **DHGM ინტეგრაცია:** `CotForwarder` — ტელემეტრია → CoT (multicast 239.2.3.1:6969 + unicast ATAK SA) და JSON (TCP :14550, newline-delimited, heartbeat + backpressure); ჩართვა Settings → DHGM forwarding. TCP კლიენტები მხოლოდ ლოკალური ქსელიდან (loopback/RFC1918/169.254) — სხვა IP ეგრევე წყდება. **dronehub.ge backend ინტეგრაცია — ჯერ არ არსებობს.**

**Core patch-ები (ყველა `custom/patches/`-შია):** ქართული ენა (`AppSettings-georgian-language`), HUD ვიჯეტების ფერები/ლოგო (`HUD-dark-theme-widgets`), იძულებითი Dark თემა (`QGCPalette-force-dark`) + ძველი patch-ები. MockLink Release-ში გამორთულია (upstream-ის ქცევა). ⚠️ core-ში პირდაპირ არაფერი ისწორება — ყოველი ცვლილება patch-ად.

**პლატფორმები/CI:** macOS · Windows (MSVC) · Linux · Android (arm64, SDK 36 / NDK r27c / Java 21) — GitHub Actions-ით; WASM ექსპერიმენტული.

**5.1 API შენიშვნები:** `adjustSettingMetaData(..., bool& userVisible)` (void; false = დამალული + default-ზე pinned); URL interceptor იხსნება `destroyQmlApplicationEngine`-ში (არა `cleanup()`-ში — engine უკვე წაშლილია); `VideoManager.gstreamerEnabled`, BrandImageSettings, `wifiReliableForCalibration`, `Vehicle::telemetryLRSSI/rcRSSI` აღარ არსებობს (→ `radioStatus` FactGroup / `rcRSSI` Fact); `QDateTime(..., Qt::UTC)` → `QTimeZone::UTC`; `Qt.labs.settings` → `QtCore`.

## სამუშაო წესი
- კოდი ჯერ, ახსნა მერე; ახსნა მოკლე
- დიდი ცვლილებამდე გეგმა დამიდასტურე
- დაშვებებს ხმამაღლა ვაცხადებ
