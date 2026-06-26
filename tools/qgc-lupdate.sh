#!/usr/bin/env bash
# DroneHub GCS — ქართული თარგმანის სტრინგების ამოღება (lupdate).
#
# რას აკეთებს: სკანავს ჩვენს custom/ წყაროებს (QML qsTr() + C++ tr()) და
# ანახლებს translations/qgc_ka.ts-ს ახალი/შეცვლილი source-ებით (თარგმანებს ინარჩუნებს).
#
# Contributor workflow (ახალი string-ის დამატება):
#   1. QML: qsTr("…") · C++: tr("…") — არა hardcode ქართული UI-ში
#   2. ./tools/qgc-lupdate.sh          # ამოიღებს source-ებს → qgc_ka.ts
#   3. თარგმნა: linguist translations/qgc_ka.ts · ან tools/apply-ka-batch2.py (batch)
#   4. PR → translations.yml CI ამოწმებს lupdate-ს (paths: custom/**, translations/**)
#
# სრული ინვენტარი (3267+ string) CI-ში: .github/workflows/translations.yml
# დარჩენილი ბათჩები: Crowdin/human. flight-mode/attitude სახელები English-ად რჩება.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$ROOT/translations/qgc_ka.ts"

# --- lupdate-ის მოძებნა (Qt 6) ---
find_lupdate() {
  if [ -n "${QT_LUPDATE:-}" ] && [ -x "${QT_LUPDATE}" ]; then echo "$QT_LUPDATE"; return; fi
  if command -v lupdate >/dev/null 2>&1; then command -v lupdate; return; fi
  # qtpaths/qmake-ით bin დირექტორიის პოვნა
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
  exit 1
fi

if [ ! -f "$TS" ]; then
  echo "!! $TS არ არსებობს" >&2; exit 1
fi

echo "==> lupdate: $LUPDATE"
echo "==> scan:    $ROOT/custom"
echo "==> ts:      $TS"

# -no-obsolete: წაშლის გამქრალ source-ებს; -locations relative: სუფთა diff.
"$LUPDATE" -locations relative -no-obsolete \
  "$ROOT/custom" \
  -ts "$TS"

echo "==> მზადაა. თარგმნე: linguist \"$TS\"  (ან Crowdin sync)"
