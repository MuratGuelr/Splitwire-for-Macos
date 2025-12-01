#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Ana Kurulum (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

# İkon Değiştirme Fonksiyonu
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    if [ ! -f "$icon_path" ] || [ ! -f "$target_file" ]; then return; fi
    cat <<EOF > /tmp/seticon.swift
import Cocoa
let args = CommandLine.arguments
guard args.count == 3 else { exit(1) }
if let image = NSImage(contentsOfFile: args[1]) {
    NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
}
EOF
    /usr/bin/swift /tmp/seticon.swift "$icon_path" "$target_file" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
    touch "$target_file"
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
title

# Intel Kontrolü
if [ "$(uname -m)" != "x86_64" ]; then
  warning "Bu betik Intel Mac'ler içindir. M1/M2/M3 için diğer klasörü kullanın."
fi

# Xcode CLT
section "Xcode Komut Satırı Araçları"
if ! xcode-select -p >/dev/null 2>&1; then
  warning "Xcode CLT kuruluyor..."
  xcode-select --install || true
fi
checkmark "Xcode CLT hazır"

# Homebrew (Intel: /usr/local)
section "Homebrew Hazırlığı"
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew kuruluyor..."
  bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  if [ -x "/usr/local/bin/brew" ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
fi
checkmark "Homebrew hazır"

section "spoofdpi Kurulumu"
if ! brew list spoofdpi &>/dev/null; then
  brew install spoofdpi
fi
# Intel binary check
SPOOFDPI_BIN=$(command -v spoofdpi || echo "/usr/local/bin/spoofdpi")
if [ ! -x "$SPOOFDPI_BIN" ]; then
    brew reinstall spoofdpi
fi
checkmark "spoofdpi binary doğrulandı"

if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord bulunamadı."
  exit 1
fi
checkmark "Discord bulundu"

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

section "Dosyalar Kopyalanıyor"
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/discord-spoofdpi.sh"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

section "Launchd Servisleri"
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  echo "  -> $filename işleniyor..."
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  launchctl bootout gui/$(id -u)/$(basename "$filename" .plist) 2>/dev/null || true
  launchctl load -w "$target_file"
done

section "Kontrol Paneli ve İkonlar"
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true

if [ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ]; then
  cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
  chmod +x "$APP_SUPPORT_DIR/SplitWire Loglar.command"
  xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Loglar.command" 2>/dev/null || true
fi

# İkonları Uygula
DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
CONSOLE_ICON="/System/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"
if [ ! -f "$CONSOLE_ICON" ]; then CONSOLE_ICON="/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"; fi

if [ -f "$DISCORD_ICON" ]; then set_icon "$DISCORD_ICON" "$APP_SUPPORT_DIR/SplitWire Kontrol.command"; fi
if [ -f "$CONSOLE_ICON" ]; then set_icon "$CONSOLE_ICON" "$APP_SUPPORT_DIR/SplitWire Loglar.command"; fi

# Kısayollar
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"
if [ -f "$DISCORD_ICON" ]; then set_icon "$DISCORD_ICON" "$DESKTOP_SHORTCUT"; fi

if [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
    LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"
    rm -f "$LOGS_SHORTCUT"
    ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$LOGS_SHORTCUT"
    if [ -f "$CONSOLE_ICON" ]; then set_icon "$CONSOLE_ICON" "$LOGS_SHORTCUT"; fi
fi

echo
hr
echo "${GRN}Intel Kurulumu tamamlandı.${RST}"