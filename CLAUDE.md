# DroneHub GCS — Claude Code Project Context

## რა არის ეს
QGroundControl-ის (Qt 6.10.1 / QML) **custom build** — ქართული Ground Control Station
დახვეწილი UI/UX-ით. Target: Windows · Linux · macOS · Android · Web (Qt WASM).

## მთავარი წესი: NO HARD-FORK
- upstream კოდს **არ ვცვლით**. ყველა ცვლილება იზოლირებულია `custom/`-ში.
- ახალ feature/safety fix-ებს ვიღებთ `git merge upstream/master`-ით.
- branding/theme/UI — QGCCorePlugin subclass + QML resource override.

## პროექტის სტრუქტურა (ამ scaffold-ში)
```
custom/
  CMakeLists.txt              # QGC_CUSTOM_BUILD=ON-ზე ეკიდება ავტომატურად
  src/CustomPlugin.{h,cc}     # QGCCorePlugin subclass + ka locale + font register
  src/CustomOptions.{h,cc}    # QGCOptions override (toolbar/colors)
  res/Custom/Theme.qml        # design tokens (ფერი/spacing) — single source
  res/fonts/                  # NotoSansGeorgian.ttf (ჩასასმელია — იხ. PLACE_FONT_HERE.md)
translations/qgc_ka.ts        # ქართული თარგმანი (ISO 639: ka)
bootstrap.sh                  # QGC-ის fork-ის შემოტანა + custom/ ჩასმა
```

## Setup (პირველი გაშვება)
```bash
./bootstrap.sh          # კლონავს QGC-ს ./qgroundcontrol-ში და symlink-ავს custom/ + ka.ts
cd qgroundcontrol
git remote add upstream https://github.com/mavlink/qgroundcontrol.git   # თუ bootstrap-მა არ დაამატა
cmake -B build -G Ninja -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

## Build constraints
- **Qt 6.10.1 ზუსტად** — სხვა ვერსია flight stability-ს არღვევს (QGC ოფიც. გაფრთხილება).
- Ninja + CMake. Android: NDK toolchain. Web: `qt-cmake` (WASM kit).

## კოდის წესები (ეთანხმება global CLAUDE.md-ს)
- Production-ready, null-safe, defensive. არანაირი `// TODO: implement` placeholder.
- Business/PID/parsing logic გამოყოფილი UI-დან. ფერი/spacing — მხოლოდ `Theme.qml`-დან.
- C++ string-ები: `tr()`; QML: `qsTr()`. ქართულის ხელით hardcode-ი QML-ში — აკრძალულია,
  ყველაფერი `qgc_ka.ts`-ში გადის lupdate-ით.
- კომიტამდე: `./tools/qgc-lupdate.sh` თუ ახალი user-facing string დაამატე.

## Roadmap
F0 bootstrap ✓ · F1 Theme/branding ✓ · F2 Fly View HUD ✓ · F3 Plan View ◑ · F4 Setup/Params ◑ · F5 QA matrix ◑ (desktop ✓ · android ✓)

> 🟢 **PRs #1–#3 merged** (master `9bd5fd2`): desktop CI (#1), Android CI (#2), translation extraction (#3).

### F3 (Plan View) — scoped
upstream-ს **არ აქვს** PlanView custom-layer hook (FlyView-ისგან განსხვავებით) → სრული
PlanView.qml override fragile hard-fork იქნებოდა (აკრძალულია). სანქცირებული lever-ები:
- `adjustSettingMetaData()` — offline Plan default = PX4 / MultiRotor (custom-example pattern).
- Plan branding ავტომატურად მოდის `paletteOverride()`-დან (PlanView იყენებს QGCPalette).
- Georgian: `qgc_ka.ts` PlanView context.

### F4 (Setup/Params) — translation pipeline ✓
- `tools/qgc-lupdate.sh` (local) + `.github/workflows/translations.yml` (manual `update_translations`)
  — extraction automation. lupdate-მა გამოავლინა **3267 string / 340 context** (სწორი context-ებით).
- `tools/apply-ka-batch2.py` + `tools/README.md` — batch UI chrome თარგმანი (safe, no flight modes).
- `translations/qgc_ka.ts` = canonical full inventory; **390 high-value UI term თარგმნილი**
  (ღილაკები/statuses/labels: FlyView, toolbar, MainWindow, PlanView, connection/status, Setup).
  flight-mode names + attitude axes (Roll/Pitch/Yaw/Loiter/...) **განზრახ English-ად**.
- ⚠️ დარჩენილი ~2877 string = Crowdin/human (pipeline + canonical .ts მზადაა).

### F2 (Fly View HUD) — შესრულდა
- `custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml` — DroneHub
  ტელემეტრიის overlay (სიმაღლე/სიჩქარე/ვერტ./მანძილი/სატელიტი/ბატარეა), Theme tokens, armed indicator.
- რეგისტრაცია: `custom.qrc` prefix `/Custom/qml` → `CustomOverrideInterceptor` გადაამისამართებს
  core-ის `qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml`-ს.
- insets სწორად — core კონტროლები პანელს არ ეფარება. Georgian → `qgc_ka.ts` `FlyViewCustomLayer` context.
- vehicle facts ვერიფიცირებულია real tree-ზე: `vehicle.{altitudeRelative,groundSpeed,climbRate,flightDistance}`, `gps.count`, `batteries.get(0).percentRemaining`.

### F5 (QA matrix) — desktop ✓ · android ✓
- `.github/workflows/build.yml` — Linux/Win/macOS custom-build CI + `concurrency` (minutes-saver). **Manual-only** (`workflow_dispatch`).
  🟢 **GREEN** (PR #1). GStreamer გათიშულია (custom plugin/QML verification).
- `.github/workflows/android.yml` — Android custom-build CI (PR #2). **Manual-only**.
- `.github/workflows/translations.yml`, `crowdin.yml` — **manual-only** (no push/PR/schedule triggers; saves CI billing).
- დარჩა: **WASM** (upstream Stable_V5.0 CI-შიც არ არის — experimental). **field test** → hardware.

### ⚠️ Qt ვერსიის გადასაწყვეტი
upstream Stable_V5.0-ის **საკუთარი CI იყენებს Qt 6.8.3-ს**, CLAUDE.md კი პინავს 6.10.1-ს.
CI default ამჟამად 6.8.3 (upstream-validated). 6.10.1 vs 6.8.3 — გუნდმა უნდა დაადასტუროს.

### F1 (branding/theme) — შესრულდა
custom/ scaffold **გადაკეთდა Stable_V5.0 API-ზე** (F0 ძველ QGCToolbox API-ს იყენებდა → არ აეწყობოდა):
- რეგისტრაცია: `CUSTOMHEADER`/`CUSTOMCLASS` compile-defs (singleton `Q_APPLICATION_STATIC`).
- CMake: `CUSTOM_SOURCES`/`CUSTOM_INCLUDE_DIRECTORIES`/`QGC_RESOURCES` cache vars (core target `${CMAKE_PROJECT_NAME}`).
- `custom/cmake/CustomOverrides.cmake` (configure-time include — სავალდებულო) · `custom/custom.qrc`.
- DroneHub branding: `DroneHubLogo.svg`, `paletteOverride()` (Theme→QGC palette), `brandImage*`, ქართული ფონტი+locale `init()`-ში.
- QML override mechanism: `createQmlApplicationEngine` + `CustomOverrideInterceptor` (F2/F3-ისთვის) · `Custom.Theme` singleton.
- ✅ ფონტი ჩამოტვირთულია (`NotoSansGeorgian.ttf`, gitignored).
- ✅ **compile-verified CI-ით** (Linux/Win/macOS, run 28231357555). Qt 6.8.3.

## აქტიური ფოკუსი
> F1–F4 implemented; PRs #1–#3 merged (desktop + Android + translations CI). **390/3267** ka UI chrome.
> შემდეგი:
> 1. F4 დარჩენილი ~2877 string — Crowdin/human (`tools/qgc-lupdate.sh` + batch scripts).
> 2. Field test — hardware (SITL/real vehicle).
> 3. Qt **6.10.1 (CLAUDE.md) vs 6.8.3 (CI)** — გუნდმა უნდა დაადასტუროს.
> 4. WASM CI — experimental; user-greenlight საჭიროა.
