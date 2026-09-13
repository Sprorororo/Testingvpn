#!/bin/bash
# Генерирует иконку SavaVPN программно (щит + галочка на зелёном фоне)
# и подменяет её во всех разрешениях, которые использует базовый APK.
set -euo pipefail

DECODED_DIR="$1"
WORK_DIR="$(mktemp -d)"

# Размеры под стандартные Android density buckets (в px, квадратные иконки)
declare -A SIZES=(
  ["mipmap-mdpi"]=48
  ["mipmap-hdpi"]=72
  ["mipmap-xhdpi"]=96
  ["mipmap-xxhdpi"]=144
  ["mipmap-xxxhdpi"]=192
)

# Рисуем простую векторную иконку через Python (Pillow) — доступно в ubuntu-latest
# после установки, без внешних бинарных assets в репозитории.
python3 - "$WORK_DIR" <<'PYEOF'
import sys
from PIL import Image, ImageDraw

out_dir = sys.argv[1]
size = 512
img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Фон - скруглённый квадрат в фирменном зелёном цвете
bg_color = (46, 125, 91, 255)  # #2E7D5B
draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=size // 5, fill=bg_color)

# Щит (символ защиты/VPN) - простой полигон
shield_color = (255, 255, 255, 255)
cx = size / 2
shield = [
    (cx, size * 0.18),
    (size * 0.78, size * 0.30),
    (size * 0.78, size * 0.55),
    (cx, size * 0.85),
    (size * 0.22, size * 0.55),
    (size * 0.22, size * 0.30),
]
draw.polygon(shield, fill=shield_color)

# Внутренняя галочка зелёным по щиту
check_color = bg_color
draw.line(
    [(size * 0.37, size * 0.50), (size * 0.46, size * 0.60), (size * 0.65, size * 0.38)],
    fill=check_color, width=int(size * 0.045), joint="curve"
)

img.save(f"{out_dir}/icon_master.png")
PYEOF

for dir_name in "${!SIZES[@]}"; do
    px="${SIZES[$dir_name]}"
    target_dir="$DECODED_DIR/res/$dir_name"
    if [ -d "$target_dir" ]; then
        python3 -c "
from PIL import Image
img = Image.open('$WORK_DIR/icon_master.png')
img = img.resize(($px, $px), Image.LANCZOS)
img.save('$target_dir/ic_launcher.png')
img.save('$target_dir/ic_launcher_round.png')
"
        echo "  icon written: $target_dir (${px}x${px})"
    fi
done

rm -rf "$WORK_DIR"
