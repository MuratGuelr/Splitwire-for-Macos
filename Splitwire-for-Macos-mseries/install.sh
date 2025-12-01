#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Ana Kurulum (Apple Silicon)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

# ----------------------------------------------------------------------
# GÜÇLENDİRİLMİŞ İKON DEĞİŞTİRME FONKSİYONU
# ----------------------------------------------------------------------
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    # Dosyalar yoksa çık
    if [ ! -f "$icon_path" ] || [ ! -f "$target_file" ]; then return; fi

    # Geçici Swift kodu oluştur
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

    # Swift ile ikonu uygula
    /usr/bin/swift /tmp/seticon.swift "$icon_path" "$target_file" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
    
    # Finder'ı yenilemeye zorla (Dosyaya dokun)
    touch "$target_file"
}
# ----------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
title

# Sadece Apple Silicon (arm64) kontrolü
if [ "$(uname -m)" != "arm64" ]; then
  error "Bu kurulum yalnızca Apple Silicon (arm64) içindir."
  exit 1
fi

# 1) Xcode CLT Kontrol (Swift için gerekli)
section "Xcode Komut Satırı Araçları"
if ! xcode-select -p >/dev/null 2>&1; then
  warning "Xcode CLT kuruluyor..."
  xcode-select --install || true
  # Kurulumun bitmesi beklenebilir ama genelde arka planda devam eder.
  # Kullanıcı zaten daha önce kurduysa burayı geçer.
fi
checkmark "Xcode Komut Satırı Araçları kontrol edildi"

# 2) Homebrew Kontrol
section "Homebrew Hazırlığı"
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew kuruluyor..."
  bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
checkmark "Homebrew hazır"

section "spoofdpi Kurulumu"
if ! brew list spoofdpi &>/dev/null; then
  brew install spoofdpi
else
  checkmark "spoofdpi zaten kurulu"
fi

# spoofdpi binary check
SPOOFDPI_BIN=$(command -v spoofdpi || echo "/opt/homebrew/bin/spoofdpi")
if [ ! -x "$SPOOFDPI_BIN" ]; then
    brew reinstall spoofdpi
fi
checkmark "spoofdpi binary doğrulandı"

# Discord Kontrol
if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord uygulaması /Applications klasöründe bulunamadı."
  exit 1
fi
checkmark "Discord bulundu"

# Dizinleri hazırla
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

section "Dosyalar Kopyalanıyor"
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/discord-spoofdpi.sh"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

section "launchd Servisleri"
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  echo "  -> $filename işleniyor..."
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  # Servisleri sıfırla
  launchctl bootout gui/$(id -u)/$(basename "$filename" .plist) 2>/dev/null || true
  launchctl load -w "$target_file"
done

section "Kontrol Paneli ve İkonlar"

# 1. Dosyaları Kopyala
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true

# 2. Log Dosyasını Kopyala
if [ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ]; then
  cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
  chmod +x "$APP_SUPPORT_DIR/SplitWire Loglar.command"
  xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Loglar.command" 2>/dev/null || true
fi

# 3. İKONLARI UYGULA (ÖNCE ANA DOSYALARA)
echo "  -> İkonlar ana dosyalara işleniyor..."

# SplitWire Kontrol -> Discord İkonu
DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$DISCORD_ICON" ]; then
    set_icon "$DISCORD_ICON" "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
fi

# SplitWire Loglar -> Konsol İkonu
CONSOLE_ICON="/System/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
if [ ! -f "$CONSOLE_ICON" ]; then
    # Eski macOS sürümleri veya farklı konumlar için yedek
    CONSOLE_ICON="/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
fi

if [ -f "$CONSOLE_ICON" ] && [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
    set_icon "$CONSOLE_ICON" "$APP_SUPPORT_DIR/SplitWire Loglar.command"
fi

section "Masaüstü Kısayolları"
# 4. Kısayolları Oluştur (İkonları miras alacaklar)

# Kontrol Kısayolu
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"
# Kısayola da ikon basmayı dene (Garanti olsun)
if [ -f "$DISCORD_ICON" ]; then set_icon "$DISCORD_ICON" "$DESKTOP_SHORTCUT"; fi

# Loglar Kısayolu
if [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
    LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"
    rm -f "$LOGS_SHORTCUT"
    ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$LOGS_SHORTCUT"
    # Kısayola da ikon basmayı dene
    if [ -f "$CONSOLE_ICON" ]; then set_icon "$CONSOLE_ICON" "$LOGS_SHORTCUT"; fi
fi

echo
hr
echo "${GRN}Kurulum başarıyla tamamlandı.${RST}"
echo "Masaüstünüzdeki ikonlar birkaç saniye içinde güncellenecektir."
echo "Eğer ikonlar değişmezse bilgisayarı yeniden başlatabilirsiniz."