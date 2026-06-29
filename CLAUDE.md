# CLAUDE.md — DroneHub GCS

> Place this file at the root of the `DroneHub-GCS/` repo (next to the `qgroundcontrol/` folder).

## რა არის ეს პროექტი
Desktop **Ground Control Station** (DroneHubGCS) — **QGroundControl-ის fork**.
Bundle ID: `org.qgroundcontrol.QGroundControl`. macOS build output:
`DroneHub-GCS/qgroundcontrol/build/Release/DroneHubGCS.app`.
დანიშნულება: PX4 (და სავარაუდოდ ArduPilot) დრონების მართვა, mission planning, telemetry, parameter tuning.

## სტეკი
- **Qt 6** (QML + C++) — QGC-ის სტანდარტული სტეკი
- **CMake** build system
- **MAVLink** პროტოკოლი vehicle-თან კომუნიკაციისთვის
- QML — UI ფენა; C++ — backend/business logic

<!-- TODO: დაადასტურე Qt-ის ზუსტი ვერსია (6.6? 6.8?) და MAVLink dialect -->

## Build & Run
<!-- TODO: ჩაანაცვლე შენი რეალური ბრძანებებით. ქვემოთ QGC-ის ტიპური flow-ია. -->
```bash
# Configure (Release)
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build --config Release -j$(sysctl -n hw.ncpu)

# Output
open build/Release/DroneHubGCS.app
```
Submodules (QGC იყენებს):
```bash
git submodule update --init --recursive
```

## არქიტექტურა (QGC fork — სად რა დევს)
- `src/` — C++ backend: `Vehicle/`, `Comms/` (MAVLink links), `MissionManager/`, `FactSystem/` (parameters)
- `src/ui/` ან `*.qml` — QML UI
- `src/FirmwarePlugin/` — PX4/ArduPilot-სპეციფიკური ლოგიკა
- `qgcresources` / `*.qrc` — resource bundles

⚠️ ეს fork-ია — **upstream-თან rebase-ის ტვირთი არსებობს**. ცვლილებები მაქსიმალურად იზოლირებულ ფაილებში/plugin-ებში გააკეთე, რომ upstream merge ნაკლებად მტკივნეული იყოს. core QGC ფაილების პირდაპირი რედაქტირება მხოლოდ აუცილებლობისას.

## კონვენციები
- C++: QGC-ის არსებულ სტილს მიჰყევი (Qt naming, `m_` prefix member-ებზე)
- QML: არსებული component-ების reuse, არა ნულიდან წერა
- ცვლილებამდე შეამოწმე ხომ არ აკეთებს QGC-ი იმავეს უკვე

## დომენური კონტექსტი
- PX4 parameter conventions, flight modes, MAVLink command set ცნობილია — ბაზისური ახსნა არ მჭირდება
- fork-ის mod-ები DroneHub-სპეციფიკურია (branding, ქართული UI, dronehub.ge ინტეგრაცია?) <!-- TODO: ჩამოწერე რა შეცვალე upstream-თან შედარებით -->

## სამუშაო წესი
- კოდი ჯერ, ახსნა მერე; ახსნა მოკლე
- დიდი ცვლილებამდე გეგმა დამიდასტურე
- დაშვებებს ხმამაღლა ვაცხადებ
