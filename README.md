# DroneHub GCS — ქართული Ground Control Station

QGroundControl-ის (Qt 6 / QML) custom build, ქართული ლოკალიზაციით და დახვეწილი UI/UX-ით.
**ბაზა:** QGC **v5.1.5** · Qt **6.11.1** · app ვერსია **1.0.0**.
Target: **Windows · Linux · macOS · Android** (+ ექსპერიმენტული Web/WASM) — ერთი codebase.

[![DroneHub Build](https://github.com/demna63/DroneHub-GCS/actions/workflows/build.yml/badge.svg)](https://github.com/demna63/DroneHub-GCS/actions/workflows/build.yml)
[![DroneHub Android](https://github.com/demna63/DroneHub-GCS/actions/workflows/android.yml/badge.svg)](https://github.com/demna63/DroneHub-GCS/actions/workflows/android.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

## 0. ჩამოტვირთვა / Install

მზა installer-ები (tag release-ის შემდეგ): [**Releases**](../../releases/latest).
build-ის წყაროდან გასაშენებლად → [§4 Build](#4-build-qt-6111-qgc-v515).

> ⚠️ სანამ code-signing სერტიფიკატები დაემატება, installer-ები **ხელმოუწერელია** —
> ქვემოთ მოცემულია OS-ის გაფრთხილების გვერდის ავლა. იხ. `docs/RELEASE.md`.

| Platform | ფაილი | Install |
|----------|-------|---------|
| **Windows** | `DroneHubGCS-*.exe` | გაუშვი installer. SmartScreen-ზე → **More info → Run anyway**. |
| **macOS** | `DroneHubGCS-*.dmg` | გახსენი, ჩაათრიე Applications-ში. „unidentified developer" → **System Settings → Privacy & Security → Open Anyway** (ან `xattr -dr com.apple.quarantine /Applications/DroneHubGCS.app`). |
| **Linux** | `DroneHubGCS_*.deb` | `sudo apt install ./DroneHubGCS_*_amd64.deb` |
| **Android** | `DroneHubGCS-arm64-v8a.apk` | ჩართე *Install unknown apps* → გახსენი APK. სანამ release keystore დაემატება, APK ტესტის გასაღებითაა ხელმოწერილი — სხვა წყაროდან დაყენებული ვერსია ჯერ წაშალე. |

---

## 1. სტრატეგია: Fork ≠ Hard-fork

**არ** ვცვლით upstream კოდს. ვიყენებთ QGC-ის ოფიციალურ `custom/` build mechanism-ს:

- ვაკეთებთ fork-ს `mavlink/qgroundcontrol`-ისგან, ვამატებთ როგორც `upstream` remote.
- ყველა ჩვენი ცვლილება იზოლირებულია `custom/` დირექტორიაში (branding, theme, UI override).
- `git merge upstream/master` — ვიღებთ ახალ feature-ებსა და safety fix-ებს კონფლიქტის გარეშე.

ეს კრიტიკულია: QGC არის flight-safety-critical. upstream-ისგან გათიშვა ნიშნავს უსაფრთხოების fix-ების დაკარგვას.

```
qgroundcontrol/            ← fork (upstream sync)
├── src/                   ← upstream (არ ვეხებით)
├── qml/                   ← upstream UI (override-ით ვცვლით, არ ვშლით)
├── translations/
│   └── qgc_ka.ts          ← ★ ქართული translation
└── custom/                ← ★ ჩვენი მთელი სამუშაო აქ
    ├── CMakeLists.txt
    ├── src/
    │   ├── CustomPlugin.h/.cc      ← QGCCorePlugin subclass
    │   └── CustomOptions.h/.cc     ← QGCOptions override
    ├── custom.qrc                  ← resource override (icon→QML)
    └── res/
        ├── Custom/Theme.qml        ← ფერთა პალიტრა
        ├── DroneHubLogo.svg
        └── fonts/NotoSansGeorgian.ttf
```

## 2. ლოკალიზაცია (ka)

QGC იყენებს Qt Linguist-ს (`tr()` C++ / `qsTr()` QML) + Crowdin sync.

- ISO 639 კოდი: **`ka`** → ფაილი `qgc_ka.ts`.
- სტრინგების ამოღება: `./tools/qgc-lupdate.sh` → ანახლებს `qgc.ts`-ს.
- ქართულის თარგმნა: Qt Linguist-ში ან Crowdin-ში.
- **JSON სტრინგები** (FactMetaData, param აღწერები) ცალკე ფაილებშია — ისიც lupdate-ით მუშავდება.

### კრიტიკული: ქართული ფონტი
QGC-ის default ფონტი (Open Sans / Roboto) **არ შეიცავს ქართულ glyph-ებს** → კვადრატები გამოჩნდება.
გადაწყვეტა: bundle `NotoSansGeorgian` (ან BPG) და fallback register აპლიკაციის init-ზე (იხ. `custom/src/CustomPlugin.cc`).

## 3. UI/UX დახვეწა — Override Layers

QML resource override-ით ვცვლით view-ებს upstream-ის შეუხებლად:

| ფენა | რას ვცვლით | ფაილი |
|------|-----------|-------|
| Theme tokens | ფერები, radius, spacing, ჩრდილები | `Custom/Theme.qml` |
| Typography | ქართული ფონტი, weight scale | `CustomPlugin.cc` (font register) |
| Toolbar | მთავარი ნავიგაცია, status indicators | `MainToolbar.qml` override |
| Fly View | HUD layout, telemetry widgets | `FlyView.qml` override |
| Plan View | mission/survey UX | `PlanView.qml` override |

**Design tokens** (იხ. `custom/res/Custom/Theme.qml`) — ერთ წყაროში თავმოყრილი, UI კოდი hardcode-ს არ შეიცავს. ეს ემთხვევა შენს CLAUDE.md-ს: business logic ≠ UI layer.

## 4. Build (Qt 6.11.1, QGC v5.1.5)

```bash
# 1. fork + submodules
git clone --recursive https://github.com/<you>/qgroundcontrol.git
cd qgroundcontrol
git remote add upstream https://github.com/mavlink/qgroundcontrol.git

# 2. custom build (CMake) — Qt 6.11.1 (upstream v5.1.x pin); macOS local: arm64-only
cmake -B build -G Ninja \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.11.1/macos" \
  -DQGC_CUSTOM_BUILD=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build

# platform targets:
#   Linux   : -DCMAKE_PREFIX_PATH="$HOME/Qt/6.11.1/gcc_64"
#   Android : -DCMAKE_TOOLCHAIN_FILE=<android-ndk>
#   WASM    : upstream 5.1-ში მხარდაჭერილი აღარ არის (ექსპერიმენტული job)
```

> **Qt 6.11.1** — canonical ვერსია (QGC v5.1.x upstream pin + CI). საჭიროა Python ≥ 3.10 და GStreamer 1.28.4.
> განახლება მხოლოდ upstream-ის ახალი pin-ის შემდეგ, სრული CI/QA GREEN-ით.

## 5. Roadmap (სრული GCS MVP)

| # | ფაზა | სტატუსი | მთავარი deliverable |
|---|------|---------|---------------------|
| F0 | Bootstrap | ✅ | fork, plugin compile, ka.ts skeleton, font hook |
| F1 | Branding/Theme | ✅ | CustomPlugin (5.1 API), `paletteOverride`, ლოგო, ფონტი+locale, Theme singleton |
| F2 | Fly View HUD | ✅ | `FlyViewCustomLayer` override — ტელემეტრიის overlay |
| F3 | Plan View | ◑ | offline-plan defaults (PX4/MultiRotor) + theme/ka *(upstream-ს Plan hook არ აქვს)* |
| F4 | Setup/Params | ◑ | `tools/qgc-lupdate.sh` + SetupView ka seed *(full translation → Crowdin)* |
| F5 | QA matrix | ✅ | CI: Linux `.deb` · Windows NSIS `.exe` · Android APK (Qt 6.11.1); macOS — ადგილობრივად + release-ზე |
| F6 | QGC 5.1 მიგრაცია | ✅ | QGC v5.1.5 / Qt 6.11.1 (Stage 1). Stage 2 — Qt 6.12, upstream pin-ის შემდეგ |

---


### Verification
ლოკალურად Qt არ არის საჭირო კოდის წასაკითხად, მაგრამ build-ისთვის:
```bash
./bootstrap.sh && cd qgroundcontrol \
  && cmake -B build -G Ninja \
     -DCMAKE_PREFIX_PATH="$HOME/Qt/6.11.1/macos" -DCMAKE_OSX_ARCHITECTURES=arm64 \
     -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release \
     -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF \
  && cmake --build build
```
ან **GitHub Actions → DroneHub Build / DroneHub Android → Run workflow** (`workflow_dispatch`, branch-ის არჩევით).

### SITL smoke test (PX4 / simulator)

```bash
./tools/start-sitl-session.sh   # opens GCS first, then PX4 (sihsim_quadx, live HUD) or simulator
```

Stops any running px4 / DroneHubGCS first (prompts unless `-y`). See `tools/README.md`
for `--simulator`, `PX4_DIR`, and `PX4_SITL_TARGET` options.

### დარჩენილი (გარე დამოკიდებულებები)
code-signing სერტიფიკატები (macOS/Windows/Android release keystore) · field test (drone hardware) · dronehub.ge backend ინტეგრაცია.

## ლიცენზია

GPLv3 — იხ. [LICENSE](LICENSE). QGroundControl-ის upstream კოდი Apache-2.0 / GPLv3 ორმაგი ლიცენზიითაა ([mavlink/qgroundcontrol](https://github.com/mavlink/qgroundcontrol)).
