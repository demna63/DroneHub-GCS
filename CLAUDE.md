# DroneHub GCS — Claude Code Project Context

## რა არის ეს
QGroundControl-ის (Qt 6.8.3 / QML) **custom build** — ქართული Ground Control Station
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
cmake -B build -G Ninja \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/macos" \
  -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release \
  -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF
cmake --build build
```

## Build constraints
- **Qt 6.8.3 (LTS) — canonical pin.** upstream Stable_V5.0 + DroneHub CI + ლოკალური build.
  სხვა Qt ვერსია QML/rendering-ის განსხვავებებს იწვევს და GCS საიმედოობაზე მოქმედებს.
- **Upgrade policy:** 6.8.3-ზე რჩებით სანამ upstream QGC ახალ Qt-ს (მაგ. 6.12 LTS) ოფიციალურად
  არ დაადასტურებს და CI/field test GREEN არ იქნება. ad-hoc 6.10.x არ გამოიყენოთ.
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
- `translations/qgc_ka.ts` = canonical full inventory; **Crowdin-ში 100% translated + approved**.
  Crowdin = source of truth → weekly sync (`crowdin.yml`) ჩამოიტანს `qgc_ka.ts`-ში.
- ⚠️ **პოლიტიკის ცვლილება:** flight-mode names ახლა **ქართულად** ითარგმნა Crowdin-ში
  (`Guided`→მართვადი, `RTL`→დაბრუნება, `Loiter`→პოზიციონირება, `Altitude Hold`→სიმაღლის შენარჩუნება).
  ანუ ძველი "flight modes intentionally English" წესი **გაუქმდა** — acronyms (GPS/EKF/PX4/...) რჩება English.

### F2 (Fly View HUD) — შესრულდა
- `custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml` — DroneHub
  ტელემეტრიის overlay (სიმაღლე/სიჩქარე/ვერტ./მანძილი/სატელიტი/ბატარეა), Theme tokens, armed indicator.
- რეგისტრაცია: `custom.qrc` prefix `/Custom/qml` → `CustomOverrideInterceptor` გადაამისამართებს
  core-ის `qrc:/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml`-ს.
- insets სწორად — core კონტროლები პანელს არ ეფარება. Georgian → `qgc_ka.ts` `FlyViewCustomLayer` context.
- vehicle facts ვერიფიცირებულია real tree-ზე: `vehicle.{altitudeRelative,groundSpeed,climbRate,flightDistance}`, `gps.count`, `batteries.get(0).percentRemaining`.

### F5 (QA matrix) — desktop ✓ · android ✓
- `.github/workflows/build.yml` — Linux/Win/macOS custom-build CI + `concurrency` (minutes-saver). **Manual-only** (`workflow_dispatch`) + **reusable** (`workflow_call`).
  🟢 **GREEN** (PR #1). GStreamer გათიშულია (custom plugin/QML verification). macOS **opt-in** (`include_macos`, 10× cost).
  ახლა აგრევე: CPack `package` → installer artifacts (.dmg/.exe/.AppImage) + secret-gated signing (`sign` input).
- `.github/workflows/release.yml` — **tag-triggered** (`v*`) release: calls build.yml (macOS+sign on) → GitHub Release + CHANGELOG notes. იხ. `docs/RELEASE.md`. ⚠️ signing secrets ჯერ არ არის → unsigned installers.
- `.github/workflows/android.yml` — Android custom-build CI (PR #2). **Manual-only**.
- `.github/workflows/translations.yml` — **manual-only** (no push/PR/schedule triggers; saves CI billing).
- `.github/workflows/crowdin.yml` — **weekly** (`cron: '0 3 * * 0'`, Sun 03:00 UTC) + manual; pulls Crowdin ka, opens `chore(l10n)` PR.
- დარჩა: **WASM** (upstream Stable_V5.0 CI-შიც არ არის — experimental). **field test** → hardware.

### Qt ვერსია — ✓ გადაწყვეტილი
**6.8.3** = upstream Stable_V5.0 + DroneHub CI + macOS SITL field test. განახლება მხოლოდ
upstream-ის მიყოლებით, როცა ახალი Qt LTS/stable ძლიერად validated იქნება.

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
> F1–F5 implemented. ka თარგმანი **Crowdin-ში 100%** (flight modes ქართულად). release pipeline
> wired (desktop installers + signing + Android APK; Windows signing test-cert-ით ვალიდირებული).
> შემდეგი (კოდის გარეთ, user action):
> 1. Real signing certs — Apple Developer ($99/წ) + Windows CA/Azure + dedicated Android keystore.
> 2. GitHub billing — spending limit/reset (macOS release job-ისთვის).
> 3. Field test — hardware (SITL ✓). WASM — experimental, opt-in.
