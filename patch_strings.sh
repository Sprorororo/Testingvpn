#!/bin/bash
# Заменяет отображаемое имя приложения на "SavaVPN (beta)" во всех values*/strings.xml
set -euo pipefail

DECODED_DIR="$1"

# app_name — стандартный ключ строки ресурса, отвечающий за имя приложения
# в лаунчере и заголовках экранов у большинства Android-приложений, включая SFA.
find "$DECODED_DIR/res" -type f -name "strings.xml" -path "*/values*/strings.xml" | while read -r f; do
    if grep -q 'name="app_name"' "$f"; then
        # Заменяем содержимое тега app_name, сохраняя остальные строки как есть
        sed -i -E 's#(<string name="app_name">)[^<]*(</string>)#\1SavaVPN (beta)\2#' "$f"
        echo "  patched: $f"
    fi
done
