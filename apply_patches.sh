#!/bin/bash
# Применяет брендинг SavaVPN к декодированному apktool APK.
# Аргумент $1 — путь к директории, куда apktool распаковал APK (например "decoded").
set -euo pipefail

DECODED_DIR="$1"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Патчим строки (название приложения) =="
bash "$PATCH_DIR/patch_strings.sh" "$DECODED_DIR"

echo "== Патчим иконку =="
bash "$PATCH_DIR/patch_icon.sh" "$DECODED_DIR"

echo "== Патчим цвета/тему =="
bash "$PATCH_DIR/patch_colors.sh" "$DECODED_DIR"

echo "== Зашиваем ссылку на подписку =="
bash "$PATCH_DIR/patch_subscription.sh" "$DECODED_DIR"

echo "Все патчи применены."
