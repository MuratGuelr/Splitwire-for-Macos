#!/usr/bin/env bash
set -euo pipefail

# --- Görsel Yardımcılar ---
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
title() { echo "${GRN}SplitWire • Kurulum (Evrensel)${RST}"; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }
checkmark() { echo "${GRN}✔${RST} $*"; }

title

# 1. Mimari ve Yollar
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
    HOMEBREW_DIR="/opt/homebrew"
else
    HOMEBREW_DIR="/usr/local"
fi

# 2. Klasörleri Hazırla
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# 3. DISCORD'U YAMALA (DOCK'TAN AÇILINCA ÇALIŞMASI İÇİN)
# ----------------------------------------------------------------------
section "Discord Uygulaması Yapılandırılıyor (Info.plist)"
DISCORD_PLIST="/Applications/Discord.app/Contents/Info.plist"

if [ -f "$DISCORD_PLIST" ]; then
    # Info.plist içine LSEnvironment ekleyerek proxy'yi zorunlu kılıyoruz
    # Bu sayede Dock'tan veya Spotlight'tan açsan bile proxy devreye girer.
    
    # Önce varsa eskileri temizle (Hata vermemesi için || true)
    /usr/libexec/PlistBuddy -c "Delete :LSEnvironment" "$DISCORD_PLIST" 2>/dev/null || true
    
    # Yeni ayarları ekle
    /usr/libexec/PlistBuddy -c "Add :LSEnvironment dict" "$DISCORD_PLIST"
    /usr/libexec/PlistBuddy -c "Add :LSEnvironment:http_proxy string http://127.0.0.1:8080" "$DISCORD_PLIST"
    /usr/libexec/PlistBuddy -c "Add :LSEnvironment:https_proxy string http://127.0.0.1:8080" "$DISCORD_PLIST"
    /usr/libexec/PlistBuddy -c "Add :LSEnvironment:all_proxy string http://127.0.0.1:8080" "$DISCORD_PLIST"
    /usr/libexec/PlistBuddy -c "Add :LSEnvironment:PATH string $HOMEBREW_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" "$DISCORD_PLIST"
    
    # Değişikliğin algılanması için uygulamayı "dürtüyoruz"
    touch "/Applications/Discord.app"
    checkmark "Discord kimlik kartına proxy ayarları işlendi."
else
    echo "${RED}HATA: Discord.app bulunamadı!${RST}"
    exit 1
fi

# ----------------------------------------------------------------------
# 4. DOSYALARI KOPYALA
# ----------------------------------------------------------------------
section "Dosyalar Kopyalanıyor"
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
# Varsa log araçlarını da kopyala
[ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ] && cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
[ -f "$SCRIPT_DIR/scripts/logs.sh" ] && cp "$SCRIPT_DIR/scripts/logs.sh" "$APP_SUPPORT_DIR/"

chmod +x "$APP_SUPPORT_DIR/"*.sh
chmod +x "$APP_SUPPORT_DIR/"*.command
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/"* 2>/dev/null || true

# ----------------------------------------------------------------------
# 5. SERVISLERİ YÜKLE
# ----------------------------------------------------------------------
section "Servisler Yükleniyor"
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  
  launchctl bootout gui/$(id -u)/$(basename "$filename" .plist) 2>/dev/null || true
  launchctl load -w "$target_file"
done

# ----------------------------------------------------------------------
# 6. İKONLAR (SWIFT İLE)
# ----------------------------------------------------------------------
set_icon() {
    if [ ! -f "$1" ] || [ ! -f "$2" ]; then return; fi
    cat <<EOF > /tmp/seticon.swift
import Cocoa
let args = CommandLine.arguments
if args.count == 3, let image = NSImage(contentsOfFile: args[1]) {
    NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
}
EOF
    /usr/bin/swift /tmp/seticon.swift "$1" "$2" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
}

DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$DISCORD_ICON" ]; then
    set_icon "$DISCORD_ICON" "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
    
    # Masaüstü Kısayolu
    rm -f "$HOME/Desktop/SplitWire Kontrol"
    ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$HOME/Desktop/SplitWire Kontrol"
    set_icon "$DISCORD_ICON" "$HOME/Desktop/SplitWire Kontrol"
fi

echo
hr
echo "${GRN}Kurulum Tamamlandı!${RST}"
echo "Discord'u artık Uygulamalar klasöründen, Dock'tan veya otomatik olarak açabilirsiniz."
echo "Lütfen şimdi Discord'u tamamen kapatıp (Cmd+Q) tekrar açın."