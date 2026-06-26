# DroneHub GCS — ქართული Ground Control Station

QGroundControl-ის (Qt 6 / QML) custom build, ქართული ლოკალიზაციით და დახვეწილი UI/UX-ით.
Target: **Windows · Linux · macOS · Android · Web (Qt WASM)** — ერთი codebase.

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

## 4. Build (Qt 6.10.1 — only)

```bash
# 1. fork + submodules
git clone --recursive https://github.com/<you>/qgroundcontrol.git
cd qgroundcontrol
git remote add upstream https://github.com/mavlink/qgroundcontrol.git

# 2. custom build (CMake)
cmake -B build -G Ninja -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build

# platform targets:
#   Android : -DCMAKE_TOOLCHAIN_FILE=<android-ndk>
#   WASM    : qt-cmake (Qt for WebAssembly kit)
```

> Qt **6.10.1 ზუსტად** — სხვა ვერსია flight stability-ს არღვევს (QGC-ის ოფიც. გაფრთხილება).

## 5. Roadmap (სრული GCS MVP)

| # | ფაზა | სტატუსი | მთავარი deliverable |
|---|------|---------|---------------------|
| F0 | Bootstrap | ✅ | fork, plugin compile, ka.ts skeleton, font hook |
| F1 | Branding/Theme | ✅ | CustomPlugin (V5.0 API), `paletteOverride`, ლოგო, ფონტი+locale, Theme singleton |
| F2 | Fly View HUD | ✅ | `FlyViewCustomLayer` override — ტელემეტრიის overlay |
| F3 | Plan View | ◑ | offline-plan defaults (PX4/MultiRotor) + theme/ka *(upstream-ს Plan hook არ აქვს)* |
| F4 | Setup/Params | ◑ | `tools/qgc-lupdate.sh` + SetupView ka seed *(full translation → Crowdin)* |
| F5 | QA matrix | ◑ | `.github/workflows/build.yml` (Linux/Win/macOS) *(execution = push)* |

> ⚠️ **Qt ვერსია:** CLAUDE.md პინავს 6.10.1-ს, upstream Stable_V5.0-ის CI კი 6.8.3-ს —
> `build.yml` default = 6.8.3. გადასაწყვეტია.

---

### Verification
ლოკალურად Qt არ არის საჭირო კოდის წასაკითხად, მაგრამ build-ისთვის:
```bash
./bootstrap.sh && cd qgroundcontrol \
  && cmake -B build -G Ninja -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release \
  && cmake --build build
```
ან **push → GitHub Actions** (`.github/workflows/build.yml`) — 3 desktop platform-ის compile-verification.

### დარჩენილი (გარე დამოკიდებულებები)
push → CI · full ka translation (Crowdin) · field test (drone hardware).
