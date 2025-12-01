#!/usr/bin/env bash
set -euo pipefail

# --- Görsel Yardımcılar ---
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Ana Kurulum (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

# ----------------------------------------------------------------------
# İKON DEĞİŞTİRME FONKSİYONU (Swift)
# ----------------------------------------------------------------------
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    if [ ! -f "$icon_path" ] || [ ! -f "$target_file" ]; then return; fi

    cat <<EOF > /tmp/seticon.swift
import Cocoa
let args = CommandLine.arguments
guard args.count == 3 else { exit(1) }
let iconPath = args[1]
let targetPath = args[2]

if let image = NSImage(contentsOfFile: iconPath) {
    let workspace = NSWorkspace.shared
    workspace.setIcon(image, forFile: targetPath, options: [])
}
EOF
    /usr/bin/swift /tmp/seticon.swift "$icon_path" "$target_file" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
    touch "$target_file"
}
# ----------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
title

# 1. Mimari Kontrolü (Intel)
if [ "$(uname -m)" != "x86_64" ]; then
  warning "Bu kurulum Intel Mac'ler içindir. M1/M2/M3 için diğer klasörü kullanın."
  # Kullanıcı yanlışlıkla çalıştırdıysa bile devam etsin mi? 
  # Genelde hata verip çıkmak daha güvenlidir ama Rosetta ile çalışıyorsa uyaralım.
fi

# 2. Xcode CLT
section "Xcode Komut Satırı Araçları"
if ! xcode-select -p >/dev/null 2>&1; then
  warning "Xcode CLT kuruluyor..."
  xcode-select --install || true
fi
checkmark "Xcode CLT kontrol edildi"

# 3. Homebrew (Intel: /usr/local)
section "Homebrew Hazırlığı"
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew kuruluyor..."
  bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  if [ -x "/usr/local/bin/brew" ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
fi
checkmark "Homebrew hazır"

# 4. SpoofDPI
section "spoofdpi Kurulumu"
if ! brew list spoofdpi &>/dev/null; then
  brew install spoofdpi
fi
# Intel binary yolu kontrolü
SPOOFDPI_BIN=$(command -v spoofdpi || echo "/usr/local/bin/spoofdpi")
if [ ! -x "$SPOOFDPI_BIN" ]; then
    brew reinstall spoofdpi
fi
checkmark "spoofdpi hazır"

# 5. Discord Kontrolü
if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord uygulaması bulunamadı."
  exit 1
fi
checkmark "Discord bulundu"

# Klasörleri Hazırla
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# 6. KRİTİK AYAR: Update Döngüsünü Kırma (settings.json)
# ----------------------------------------------------------------------
section "Discord Ayarları Yapılandırılıyor"
DISCORD_CONFIG_DIR="$HOME/Library/Application Support/discord"
mkdir -p "$DISCORD_CONFIG_DIR"
SETTINGS_FILE="$DISCORD_CONFIG_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{"SKIP_HOST_UPDATE": true}' > "$SETTINGS_FILE"
    checkmark "Ayar dosyası oluşturuldu (SKIP_HOST_UPDATE)."
else
    if ! grep -q "SKIP_HOST_UPDATE" "$SETTINGS_FILE"; then
        # JSON'un sonuna ayarı ekle
        sed -i '' '$ s/}/, "SKIP_HOST_UPDATE": true }/' "$SETTINGS_FILE" 2>/dev/null || echo '{"SKIP_HOST_UPDATE": true}' > "$SETTINGS_FILE"
        checkmark "Ayar dosyası güncellendi (Update atlatıldı)."
    else
        checkmark "Ayar zaten mevcut."
    fi
fi

# 7. Dosyaları Kopyala
section "Dosyalar Kopyalanıyor"
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
if [ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ]; then
    cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
fi
if [ -f "$SCRIPT_DIR/scripts/logs.sh" ]; then
    cp "$SCRIPT_DIR/scripts/logs.sh" "$APP_SUPPORT_DIR/"
fi

# İzinleri Ver
chmod +x "$APP_SUPPORT_DIR/"*.sh
chmod +x "$APP_SUPPORT_DIR/"*.command
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/"* 2>/dev/null || true

# 8. Servisleri Yükle
section "Servisler Yükleniyor"
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  echo "  -> $filename işleniyor..."
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  
  # Eski servisi durdur ve yenisini yükle
  launchctl bootout gui/$(id -u)/$(basename "$filename" .plist) 2>/dev/null || true
  launchctl load -w "$target_file"
done

# 9. İkonlar ve Kısayollar
section "İkonlar ve Kısayollar"

DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
CONSOLE_ICON="/System/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
if [ ! -f "$CONSOLE_ICON" ]; then CONSOLE_ICON="/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"; fi

# Ana dosyalara ikon bas
if [ -f "$DISCORD_ICON" ]; then 
    echo "  -> Kontrol Paneli ikonu işleniyor..."
    set_icon "$DISCORD_ICON" "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
fi
if [ -f "$CONSOLE_ICON" ] && [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then 
    echo "  -> Log Aracı ikonu işleniyor..."
    set_icon "$CONSOLE_ICON" "$APP_SUPPORT_DIR/SplitWire Loglar.command"
fi

# Masaüstü Kısayolları
DESKTOP_CTRL="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_CTRL"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_CTRL"
if [ -f "$DISCORD_ICON" ]; then set_icon "$DISCORD_ICON" "$DESKTOP_CTRL"; fi

if [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
    DESKTOP_LOGS="$HOME/Desktop/SplitWire Loglar"
    rm -f "$DESKTOP_LOGS"
    ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$DESKTOP_LOGS"
    if [ -f "$CONSOLE_ICON" ]; then set_icon "$CONSOLE_ICON" "$DESKTOP_LOGS"; fi
fi

echo
hr
echo "${GRN}Intel Kurulumu ve Ayarlar Tamamlandı!${RST}"
echo "Discord'u yeniden başlatabilirsiniz."