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
F0 bootstrap ✓ · F1 Theme/branding ✓ · F2 Fly View HUD ✓ · F3 Plan View ◑ · F4 Setup/Params ◑ · F5 QA matrix ◑

### F3 (Plan View) — scoped
upstream-ს **არ აქვს** PlanView custom-layer hook (FlyView-ისგან განსხვავებით) → სრული
PlanView.qml override fragile hard-fork იქნებოდა (აკრძალულია). სანქცირებული lever-ები:
- `adjustSettingMetaData()` — offline Plan default = PX4 / MultiRotor (custom-example pattern).
- Plan branding ავტომატურად მოდის `paletteOverride()`-დან (PlanView იყენებს QGCPalette).
- Georgian: `qgc_ka.ts` PlanView context.

### F4 (Setup/Params) — scoped
- `tools/qgc-lupdate.sh` — **შეიქმნა** (CLAUDE.md რეფერენსავდა, არ არსებობდა). lupdate runner custom/-ზე.
- `qgc_ka.ts` SetupView context — key terms seed.
- ⚠️ "full ka translation" = Crowdin/human effort (ათასობით string) — tooling მზადაა, შიგთავსი არა.

### F2 (Fly View HUD) — შესრულდა
- `custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml` — DroneHub
  ტელემეტრიის overlay (სიმაღლე/სიჩქარე/ვერტ./მანძილი/სატელიტი/ბატარეა), Theme tokens, armed indicator.
- რეგისტრაცია: `custom.qrc` prefix `/Custom/qml` → `CustomOverrideInterceptor` გადაამისამართებს
  core-ის `qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml`-ს.
- insets სწორად — core კონტროლები პანელს არ ეფარება. Georgian → `qgc_ka.ts` `FlyViewCustomLayer` context.
- vehicle facts ვერიფიცირებულია real tree-ზე: `vehicle.{altitudeRelative,groundSpeed,climbRate,flightDistance}`, `gps.count`, `batteries.get(0).percentRemaining`.

### F5 foundation
- `.github/workflows/build.yml` — Linux/Win/macOS custom-build CI (clone QGC + copy custom/ + build).
  ეს არის რეალური compile-verification. Android/WASM jobs — ჩონჩხად.

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
- ✅ ფონტი ჩამოტვირთულია (`NotoSansGeorgian.ttf`, gitignored). ✅ QGC tree shallow-cloned `qgroundcontrol/`-ში.
- ⚠️ compile-verified **არ არის** (საჭიროა Qt 6.10.1 + recursive submodules); API ვერიფიცირებულია QGC-ის custom-example-ზე.

## აქტიური ფოკუსი
> F1–F4 კოდი/scaffold მზადაა. დარჩენილი მუშაობა **გარემოს გარეთაა**:
> 1. **push → GitHub Actions `build.yml`** = რეალური compile-verification (3 desktop platform).
> 2. F4 full ka translation — Crowdin/human (tooling `tools/qgc-lupdate.sh` მზადაა).
> 3. F5 field test — drone hardware.
> Qt 6.10.1 vs 6.8.3 გადაწყვეტა — იხ. Build constraints.
