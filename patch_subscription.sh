#!/bin/bash
# Добавляет собственный простой экран приветствия SavaVPN, который
# показывает зашитую ссылку на подписку и по кнопке "Подключить"
# вызывает официальный deep-link sing-box://import-remote-profile,
# после чего передаёт управление оригинальному главному экрану приложения.
#
# Ничего не запускается автоматически при старте — только по явному
# нажатию пользователя, что снижает риск краша при первом запуске.
set -euo pipefail

DECODED_DIR="$1"
SUBSCRIPTION_URL="https://gitverse.ru/api/repos/S_pro/Sava/raw/branch/main/Sava2.txt"
SUBSCRIPTION_NAME="SavaVPN"

SMALI_DIR="$DECODED_DIR/smali/com/sava/vpn"
mkdir -p "$SMALI_DIR"

urlencode() {
    python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

ENCODED_URL="$(urlencode "$SUBSCRIPTION_URL")"
ENCODED_NAME="$(urlencode "$SUBSCRIPTION_NAME")"
DEEP_LINK="sing-box://import-remote-profile?url=${ENCODED_URL}#${ENCODED_NAME}"

echo "  deep link: $DEEP_LINK"

MANIFEST="$DECODED_DIR/AndroidManifest.xml"

ORIGINAL_LAUNCHER=$(python3 - "$MANIFEST" <<'PYEOF'
import sys
import xml.etree.ElementTree as ET

ns_uri = 'http://schemas.android.com/apk/res/android'
tree = ET.parse(sys.argv[1])
root = tree.getroot()
app = root.find('application')
for activity in app.findall('activity'):
    for filt in activity.findall('intent-filter'):
        actions = [a.get(f'{{{ns_uri}}}name') for a in filt.findall('action')]
        cats = [c.get(f'{{{ns_uri}}}name') for c in filt.findall('category')]
        if 'android.intent.action.MAIN' in actions and 'android.intent.category.LAUNCHER' in cats:
            print(activity.get(f'{{{ns_uri}}}name'))
            sys.exit(0)
print("")
PYEOF
)

if [ -z "$ORIGINAL_LAUNCHER" ]; then
    echo "  ВНИМАНИЕ: не найдена оригинальная launcher-activity."
    echo "  Патч экрана приглашения пропущен (не критично — базовое приложение"
    echo "  всё равно откроется, подписку можно будет добавить вручную через 'add profile')."
    exit 0
fi

PACKAGE_NAME=$(grep -oP 'package="\K[^"]+' "$MANIFEST" | head -1)
if [[ "$ORIGINAL_LAUNCHER" == .* ]]; then
    ORIGINAL_LAUNCHER_FULL="${PACKAGE_NAME}${ORIGINAL_LAUNCHER}"
else
    ORIGINAL_LAUNCHER_FULL="$ORIGINAL_LAUNCHER"
fi
ORIGINAL_LAUNCHER_SMALI="L${ORIGINAL_LAUNCHER_FULL//./\/};"

echo "  original launcher: $ORIGINAL_LAUNCHER_FULL"

cat > "$SMALI_DIR/WelcomeActivity.smali" <<SMALI
.class public Lcom/sava/vpn/WelcomeActivity;
.super Landroid/app/Activity;
.source "WelcomeActivity.java"


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 8
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    const-string v0, "sava_launcher_prefs"
    const/4 v1, 0x0
    invoke-virtual {p0, v0, v1}, Landroid/app/Activity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    const-string v1, "subscription_imported"
    const/4 v2, 0x0
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v2

    if-eqz v2, :show_welcome_screen

    invoke-direct {p0, $ORIGINAL_LAUNCHER_SMALI}, Lcom/sava/vpn/WelcomeActivity;->openMain(Ljava/lang/Class;)V
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void

    :show_welcome_screen
    new-instance v3, Landroid/widget/LinearLayout;
    invoke-direct {v3, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v4, 0x1
    invoke-virtual {v3, v4}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/16 v5, 0x50
    invoke-virtual {v3, v5, v5, v5, v5}, Landroid/widget/LinearLayout;->setPadding(IIII)V
    const/high16 v6, -0x1000000
    invoke-virtual {v3, v6}, Landroid/widget/LinearLayout;->setBackgroundColor(I)V

    new-instance v6, Landroid/widget/TextView;
    invoke-direct {v6, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string v7, "SavaVPN (beta)"
    invoke-virtual {v6, v7}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/high16 v7, 0x41c00000
    invoke-virtual {v6, v7}, Landroid/widget/TextView;->setTextSize(F)V
    const v7, -0xff34cd
    invoke-virtual {v6, v7}, Landroid/widget/TextView;->setTextColor(I)V
    invoke-virtual {v3, v6}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v7, Landroid/widget/TextView;
    invoke-direct {v7, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const-string p1, "Готовы подключить сервер SavaVPN? Всё уже настроено \u2014 просто нажмите кнопку ниже."
    invoke-virtual {v7, p1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/high16 p1, 0x41000000
    invoke-virtual {v7, p1}, Landroid/widget/TextView;->setTextSize(F)V
    invoke-virtual {v3, v7}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance p1, Landroid/widget/Button;
    invoke-direct {p1, p0}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V
    const-string v0, "Подключить"
    invoke-virtual {p1, v0}, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V

    new-instance v0, Lcom/sava/vpn/WelcomeActivity\$1;
    invoke-direct {v0, p0}, Lcom/sava/vpn/WelcomeActivity\$1;-><init>(Lcom/sava/vpn/WelcomeActivity;)V
    invoke-virtual {p1, v0}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View\$OnClickListener;)V

    invoke-virtual {v3, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    invoke-virtual {p0, v3}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
    return-void
.end method

.method private openMain(Ljava/lang/Class;)V
    .locals 1
    .param p1, "target"
    new-instance v0, Landroid/content/Intent;
    invoke-direct {v0, p0, p1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    return-void
.end method

.method public onConnectClicked()V
    .locals 4
    const-string v0, "android.intent.action.VIEW"
    const-string v1, "$DEEP_LINK"
    invoke-static {v1}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;
    move-result-object v1
    new-instance v2, Landroid/content/Intent;
    invoke-direct {v2, v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;Landroid/net/Uri;)V
    invoke-virtual {p0, v2}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V

    const-string v0, "sava_launcher_prefs"
    const/4 v1, 0x0
    invoke-virtual {p0, v0, v1}, Landroid/app/Activity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0
    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences\$Editor;
    move-result-object v0
    const-string v1, "subscription_imported"
    const/4 v2, 0x1
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences\$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences\$Editor;
    move-result-object v0
    invoke-interface {v0}, Landroid/content/SharedPreferences\$Editor;->apply()V

    invoke-direct {p0, $ORIGINAL_LAUNCHER_SMALI}, Lcom/sava/vpn/WelcomeActivity;->openMain(Ljava/lang/Class;)V
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void
.end method
SMALI

cat > "$SMALI_DIR/WelcomeActivity\$1.smali" <<SMALI
.class Lcom/sava/vpn/WelcomeActivity\$1;
.super Ljava/lang/Object;
.source "WelcomeActivity.java"
.implements Landroid/view/View\$OnClickListener;

.field final synthetic this\$0:Lcom/sava/vpn/WelcomeActivity;

.method constructor <init>(Lcom/sava/vpn/WelcomeActivity;)V
    .locals 0
    iput-object p1, p0, Lcom/sava/vpn/WelcomeActivity\$1;->this\$0:Lcom/sava/vpn/WelcomeActivity;
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public onClick(Landroid/view/View;)V
    .locals 1
    iget-object v0, p0, Lcom/sava/vpn/WelcomeActivity\$1;->this\$0:Lcom/sava/vpn/WelcomeActivity;
    invoke-virtual {v0}, Lcom/sava/vpn/WelcomeActivity;->onConnectClicked()V
    return-void
.end method
SMALI

echo "  smali written: WelcomeActivity + inner OnClickListener"

python3 - "$MANIFEST" "$ORIGINAL_LAUNCHER_FULL" <<'PYEOF'
import sys
import xml.etree.ElementTree as ET

ns_uri = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ns_uri)

manifest_path = sys.argv[1]
original_launcher_full = sys.argv[2]

tree = ET.parse(manifest_path)
root = tree.getroot()
app = root.find('application')

for activity in app.findall('activity'):
    name = activity.get(f'{{{ns_uri}}}name')
    if name == original_launcher_full or (name and name.startswith('.') and original_launcher_full.endswith(name)):
        for filt in list(activity.findall('intent-filter')):
            actions = [a.get(f'{{{ns_uri}}}name') for a in filt.findall('action')]
            if 'android.intent.action.MAIN' in actions:
                activity.remove(filt)

new_activity = ET.SubElement(app, 'activity')
new_activity.set(f'{{{ns_uri}}}name', 'com.sava.vpn.WelcomeActivity')
new_activity.set(f'{{{ns_uri}}}exported', 'true')
intent_filter = ET.SubElement(new_activity, 'intent-filter')
action = ET.SubElement(intent_filter, 'action')
action.set(f'{{{ns_uri}}}name', 'android.intent.action.MAIN')
category = ET.SubElement(intent_filter, 'category')
category.set(f'{{{ns_uri}}}name', 'android.intent.category.LAUNCHER')

tree.write(manifest_path, encoding='utf-8', xml_declaration=True)
print("  manifest patched: launcher switched to com.sava.vpn.WelcomeActivity")
PYEOF
