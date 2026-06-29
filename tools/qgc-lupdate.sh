#!/usr/bin/env bash
# DroneHub GCS — ქართული თარგმანის სტრინგების ამოღება (lupdate).
#
# რას აკეთებს: ანახლებს translations/qgc_ka.ts-ს ახალი/შეცვლილი source-ებით (თარგმანებს ინარჩუნებს).
#
# Contributor workflow (ახალი string-ის დამატება):
#   1. QML: qsTr("…") · C++: tr("…") — არა hardcode ქართული UI-ში
#   2. ./tools/qgc-lupdate.sh          # ამოიღებს source-ებს → qgc_ka.ts
#   3. თარგმნა: ./tools/apply-ka-translations.sh · Crowdin · Qt Linguist
#   4. PR → translations.yml CI ამოწმებს lupdate-ს (paths: custom/**, translations/**)
#
# სრული ინვენტარი (3300+ string) CI-ში: .github/workflows/translations.yml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$ROOT/translations/qgc_ka.ts"
QGC="$ROOT/qgroundcontrol"

# --- Preferred: full QGC inventory via CMake update_translations ---
if [[ -f "$QGC/build/CMakeCache.txt" ]]; then
  echo "==> full inventory: cmake --build $QGC/build --target update_translations"
  cmake --build "$QGC/build" --target update_translations
  echo "==> მზადაა. თარგმნე: ./tools/apply-ka-translations.sh  (ან Crowdin / linguist)"
  exit 0
fi

# --- Fallback: custom/-only scan (upstream strings may become obsolete — avoid for bulk work) ---
find_lupdate() {
  if [ -n "${QT_LUPDATE:-}" ] && [ -x "${QT_LUPDATE}" ]; then echo "$QT_LUPDATE"; return; fi
  if command -v lupdate >/dev/null 2>&1; then command -v lupdate; return; fi
  for q in qtpaths6 qtpaths qmake6 qmake; do
    if command -v "$q" >/dev/null 2>&1; then
      local bindir
      bindir="$("$q" -query QT_INSTALL_BINS 2>/dev/null || true)"
      [ -n "$bindir" ] && [ -x "$bindir/lupdate" ] && { echo "$bindir/lupdate"; return; }
    fi
  done
  return 1
}

LUPDATE="$(find_lupdate || true)"
if [ -z "$LUPDATE" ]; then
  echo "!! lupdate ვერ მოიძებნა. დააყენე Qt 6 ან მიუთითე: QT_LUPDATE=/path/to/lupdate $0" >&2
  echo "!! ან გაუშვი bootstrap + cmake configure და გამოიყენე update_translations." >&2
  exit 1
fi

if [ ! -f "$TS" ]; then
  echo "!! $TS არ არსებობს" >&2; exit 1
fi

echo "!! WARN: qgroundcontrol/build არ არსებობს — custom-only lupdate (არ გამოიყენო bulk sync-ისთვის)." >&2
echo "==> lupdate: $LUPDATE"
echo "==> scan:    $ROOT/custom"
echo "==> ts:      $TS"

LUPDATE_FLAGS=(-locations relative)
if [ "${PRUNE_CUSTOM_OBSOLETE:-}" = "1" ]; then
  LUPDATE_FLAGS+=(-no-obsolete)
fi

"$LUPDATE" "${LUPDATE_FLAGS[@]}" \
  "$ROOT/custom" \
  -ts "$TS"

echo "==> მზადაა. თარგმნე: ./tools/apply-ka-translations.sh  (ან Crowdin / linguist)"
