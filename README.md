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

1. **F0 — Bootstrap**: fork, custom plugin compile, ka.ts skeleton, ფონტი → "Hello ქართულად".
2. **F1 — Branding/Theme**: DroneHub პალიტრა, ლოგო, splash, toolbar redesign.
3. **F2 — Fly View**: HUD + telemetry widget redesign, ქართული labels.
4. **F3 — Plan View**: mission/survey UX დახვეწა.
5. **F4 — Setup/Params**: firmware flash, param editor, full ka translation.
6. **F5 — QA**: 4 platform build matrix (GitHub Actions), field test.

---

### შემდეგი ნაბიჯი
ამ პაკეტში არის F0-ის scaffold (custom plugin, theme, ka.ts, font hook).
თქმა — გავაგრძელო რომელი ფენით: **Theme/branding** თუ **Fly View HUD redesign**.
