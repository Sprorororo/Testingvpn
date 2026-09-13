#!/bin/bash
# Аккуратно подменяет акцентные цвета приложения на фирменную палитру SavaVPN,
# если в colors.xml есть соответствующие стандартные ключи Material.
# Если ключей нет — ничего не ломаем, просто пропускаем (не критично для MVP).
set -euo pipefail

DECODED_DIR="$1"
COLORS_FILE="$DECODED_DIR/res/values/colors.xml"

# Фирменная палитра SavaVPN
declare -A REPLACEMENTS=(
  ["colorPrimary"]="#2E7D5B"
  ["colorPrimaryDark"]="#1F5A40"
  ["colorAccent"]="#2E7D5B"
  ["colorSecondary"]="#DFF3E8"
)

if [ ! -f "$COLORS_FILE" ]; then
    echo "  colors.xml не найден по ожидаемому пути, пропускаем патч цвета (не критично)"
    exit 0
fi

for key in "${!REPLACEMENTS[@]}"; do
    value="${REPLACEMENTS[$key]}"
    if grep -q "name=\"$key\"" "$COLORS_FILE"; then
        sed -i -E "s#(<color name=\"$key\">)[^<]*(</color>)#\1${value}\2#" "$COLORS_FILE"
        echo "  patched color: $key -> $value"
    fi
done
