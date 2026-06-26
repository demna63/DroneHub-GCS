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
F0 bootstrap ✓ · F1 Theme/branding · F2 Fly View HUD · F3 Plan View · F4 Setup/Params · F5 QA matrix

## აქტიური ფოკუსი
> შემდეგი: F1 (Theme/branding) ან F2 (Fly View HUD) — დასადასტურებელია.
