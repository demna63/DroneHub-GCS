# DroneHub GCS — ქართული Ground Control Station

QGroundControl-ის (Qt 6 / QML) custom build, ქართული ლოკალიზაციით და დახვეწილი UI/UX-ით.
Target: **Windows · Linux · macOS · Android · Web (Qt WASM)** — ერთი codebase.

---

## 0. ჩამოტვირთვა / Install

მზა installer-ები (tag release-ის შემდეგ): [**Releases**](../../releases/latest).
build-ის წყაროდან გასაშენებლად → [§4 Build](#4-build-qt-683).

> ⚠️ სანამ code-signing სერტიფიკატები დაემატება, installer-ები **ხელმოუწერელია** —
> ქვემოთ მოცემულია OS-ის გაფრთხილების გვერდის ავლა. იხ. `docs/RELEASE.md`.

| Platform | ფაილი | Install |
|----------|-------|---------|
| **Windows** | `DroneHubGCS-*.exe` | გაუშვი installer. SmartScreen-ზე → **More info → Run anyway**. |
| **macOS** | `DroneHubGCS-*.dmg` | გახსენი, ჩაათრიე Applications-ში. „unidentified developer" → **System Settings → Privacy & Security → Open Anyway** (ან `xattr -dr com.apple.quarantine /Applications/DroneHubGCS.app`). |
| **Linux** | `DroneHubGCS-*.AppImage` | `chmod +x DroneHubGCS-*.AppImage && ./DroneHubGCS-*.AppImage` |
| **Android** | `*.apk` (unsigned) | ჩართე *Install unknown apps* → გახსენი APK. |

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

## 4. Build (Qt 6.8.3)

```bash
# 1. fork + submodules
git clone --recursive https://github.com/<you>/qgroundcontrol.git
cd qgroundcontrol
git remote add upstream https://github.com/mavlink/qgroundcontrol.git

# 2. custom build (CMake) — Qt 6.8.3 LTS (upstream Stable_V5.0 pin)
cmake -B build -G Ninja \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/macos" \
  -DQGC_CUSTOM_BUILD=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF
cmake --build build

# platform targets:
#   Linux   : -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/gcc_64"
#   Android : -DCMAKE_TOOLCHAIN_FILE=<android-ndk>
#   WASM    : qt-cmake (Qt 6.8.3 for WebAssembly kit)
```

> **Qt 6.8.3** — canonical ვერსია (upstream + CI + field test). განახლება მხოლოდ upstream-ის
> ახალი LTS/stable pin-ის შემდეგ, სრული CI/QA GREEN-ით.

## 5. Roadmap (სრული GCS MVP)

| # | ფაზა | სტატუსი | მთავარი deliverable |
|---|------|---------|---------------------|
| F0 | Bootstrap | ✅ | fork, plugin compile, ka.ts skeleton, font hook |
| F1 | Branding/Theme | ✅ | CustomPlugin (V5.0 API), `paletteOverride`, ლოგო, ფონტი+locale, Theme singleton |
| F2 | Fly View HUD | ✅ | `FlyViewCustomLayer` override — ტელემეტრიის overlay |
| F3 | Plan View | ◑ | offline-plan defaults (PX4/MultiRotor) + theme/ka *(upstream-ს Plan hook არ აქვს)* |
| F4 | Setup/Params | ◑ | `tools/qgc-lupdate.sh` + SetupView ka seed *(full translation → Crowdin)* |
| F5 | QA matrix | ◑ | `.github/workflows/build.yml` (Linux/Win/macOS, Qt 6.8.3) |

---


### Verification
ლოკალურად Qt არ არის საჭირო კოდის წასაკითხად, მაგრამ build-ისთვის:
```bash
./bootstrap.sh && cd qgroundcontrol \
  && cmake -B build -G Ninja \
     -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/macos" \
     -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release \
     -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF \
  && cmake --build build
```
ან **push → GitHub Actions** (`.github/workflows/build.yml`) — 3 desktop platform-ის compile-verification.

### SITL smoke test (PX4 / simulator)

```bash
./tools/start-sitl-session.sh   # opens GCS first, then PX4 (sihsim_quadx, live HUD) or simulator
```

Stops any running px4 / DroneHubGCS first (prompts unless `-y`). See `tools/README.md`
for `--simulator`, `PX4_DIR`, and `PX4_SITL_TARGET` options.

### დარჩენილი (გარე დამოკიდებულებები)
push → CI · full ka translation (Crowdin) · field test (drone hardware).
