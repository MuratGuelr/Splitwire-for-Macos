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
# İKON DEĞİŞTİRME FONKSİYONU (Swift kullanarak, ek araç gerektirmez)
# ----------------------------------------------------------------------
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    if [ ! -f "$icon_path" ] || [ ! -f "$target_file" ]; then return; fi

    cat <<EOF > /tmp/seticon.swift
import AppKit
let args = CommandLine.arguments
guard args.count == 3 else { exit(1) }
if let image = NSImage(contentsOfFile: args[1]) {
    if NSWorkspace.shared.setIcon(image, forFile: args[2], options: []) { exit(0) }
}
exit(1)
EOF
    /usr/bin/swift /tmp/seticon.swift "$icon_path" "$target_file" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
}
# ----------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
title

# Sadece Apple Silicon (arm64) kontrolü
if [ "$(uname -m)" != "arm64" ]; then
  error "Bu kurulum yalnızca Apple Silicon (arm64) içindir."
  exit 1
fi

# 1) Xcode CLT Kontrol
section "Xcode Komut Satırı Araçları"
if ! xcode-select -p >/dev/null 2>&1; then
  warning "Xcode CLT kuruluyor..."
  xcode-select --install || true
  # Basit bekleme döngüsü yerine kullanıcıyı bilgilendirip devam edelim
  # Swift ikon değişimi için CLT lazım ama kurulum devam etmeli.
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
  launchctl unload "$target_file" 2>/dev/null || true
  launchctl load -w "$target_file"
done

section "Kontrol Paneli & Kısayollar"
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true

# Kısayol oluştur
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"

# Loglar
if [ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ]; then
  cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
  chmod +x "$APP_SUPPORT_DIR/SplitWire Loglar.command"
  xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Loglar.command" 2>/dev/null || true
  
  LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"
  rm -f "$LOGS_SHORTCUT"
  ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$LOGS_SHORTCUT"
fi

section "İkonlar Ayarlanıyor"
# 1. Kontrol Paneli -> Discord İkonu
DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$DESKTOP_SHORTCUT" ] && [ -f "$DISCORD_ICON" ]; then
    echo "  -> Kontrol paneli ikonu: Discord"
    set_icon "$DISCORD_ICON" "$DESKTOP_SHORTCUT"
fi

# 2. Loglar -> Konsol İkonu
CONSOLE_ICON_1="/System/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
CONSOLE_ICON_2="/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"

if [ -f "$LOGS_SHORTCUT" ]; then
    echo "  -> Log aracı ikonu: Konsol"
    if [ -f "$CONSOLE_ICON_1" ]; then set_icon "$CONSOLE_ICON_1" "$LOGS_SHORTCUT"
    elif [ -f "$CONSOLE_ICON_2" ]; then set_icon "$CONSOLE_ICON_2" "$LOGS_SHORTCUT"
    fi
fi

echo
hr
echo "${GRN}Kurulum başarıyla tamamlandı.${RST}"
echo "Masaüstünüzdeki 'SplitWire Kontrol' ile başlatabilirsiniz."