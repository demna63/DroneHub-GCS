#!/usr/bin/env bash
# DroneHub GCS — bootstrap.
# Clones QGroundControl, wires this repo's custom/ + translations into it.
# idempotent: ხელახლა გაშვება უსაფრთხოა.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QGC_DIR="$ROOT/qgroundcontrol"
QGC_TAG="${QGC_TAG:-Stable_V5.0}"   # pin; override: QGC_TAG=master ./bootstrap.sh

echo "==> DroneHub GCS bootstrap"
echo "    root: $ROOT"
echo "    QGC tag: $QGC_TAG"

# 1. QGC წყაროები (recursive submodules)
if [ ! -d "$QGC_DIR/.git" ]; then
  echo "==> cloning QGroundControl ($QGC_TAG)..."
  git clone --recursive --branch "$QGC_TAG" \
    https://github.com/mavlink/qgroundcontrol.git "$QGC_DIR"
else
  echo "==> QGC already present, syncing submodules..."
  git -C "$QGC_DIR" submodule update --init --recursive
fi

# 2. upstream remote (merge-ისთვის)
if ! git -C "$QGC_DIR" remote | grep -q '^upstream$'; then
  git -C "$QGC_DIR" remote add upstream https://github.com/mavlink/qgroundcontrol.git
fi

# 3. ჩვენი custom/ ჩასმა QGC-ში (symlink — ერთი წყარო)
echo "==> linking custom/ and translations into QGC..."
rm -rf "$QGC_DIR/custom"
ln -s "$ROOT/custom" "$QGC_DIR/custom"
ln -sf "$ROOT/translations/qgc_ka.ts" "$QGC_DIR/translations/qgc_ka.ts"
# cmake cache / older wiring may reference qgc_source_ka.ts — same canonical file
ln -sf "$ROOT/translations/qgc_ka.ts" "$QGC_DIR/translations/qgc_source_ka.ts"

# Qt 6 qmlcache compiles custom QML from QGC src paths — sync before build.
ln -sf "$ROOT/custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewCustomLayer.qml" \
       "$QGC_DIR/src/FlightDisplay/FlyViewCustomLayer.qml"
ln -sf "$ROOT/custom/res/Custom/qml/QGroundControl/FlightDisplay/FlyViewToolStripActionList.qml" \
       "$QGC_DIR/src/FlightDisplay/FlyViewToolStripActionList.qml"
ln -sf "$ROOT/custom/res/Custom/qml/QGroundControl/Controls/FlyViewToolBar.qml" \
       "$QGC_DIR/src/QmlControls/FlyViewToolBar.qml"

# 3b. Copy custom application icon into deploy folders
if [ -f "$ROOT/custom/res/icons/macx.icns" ]; then
  cp "$ROOT/custom/res/icons/macx.icns" "$QGC_DIR/deploy/macos/macx.icns"
fi

# 4. font sanity check
if [ ! -f "$ROOT/custom/res/fonts/NotoSansGeorgian.ttf" ]; then
  echo "!!  ფონტი არ მოიძებნა: custom/res/fonts/NotoSansGeorgian.ttf"
  echo "    ჩასვი ფონტი (იხ. custom/res/fonts/PLACE_FONT_HERE.md) build-მდე."
fi

cat <<EOF

==> მზადაა. შემდეგ:
    cd qgroundcontrol
    cmake -B build -G Ninja \\
      -DCMAKE_PREFIX_PATH="\$HOME/Qt/6.8.3/macos" \\
      -DQGC_CUSTOM_BUILD=ON -DCMAKE_BUILD_TYPE=Release \\
      -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF
    cmake --build build

    Qt 6.8.3 LTS (upstream Stable_V5.0 pin). (Android: NDK toolchain; Web: qt-cmake WASM kit.)
EOF
