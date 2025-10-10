#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

# Görsel yardımcılar (yalnızca çıktı, davranışı değiştirmez)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Ana Kurulum (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

title

# Homebrew kurulumunu ve PATH ayarını geliştir
setup_homebrew() {
  section "Homebrew Hazırlığı"
  if ! command -v brew >/dev/null 2>&1; then
    warning "Homebrew bulunamadı, kuruluyor…"
    bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  fi
  
  # Homebrew PATH'ini ayarla
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "Homebrew (Apple Silicon) PATH ayarlandı: /opt/homebrew"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    echo "Homebrew (Intel) PATH ayarlandı: /usr/local"
  else
    error "Homebrew kurulumu başarısız oldu"
    exit 1
  fi
}

setup_homebrew
checkmark "Homebrew hazır"

# spoofdpi kurulumunu geliştir
setup_spoofdpi() {
  section "spoofdpi Kurulumu"
  if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kurulu değil, Homebrew ile kuruluyor..."
    brew install spoofdpi
  fi
  
  # spoofdpi binary'sinin varlığını kontrol et
  local spoofdpi_path=""
  if [ -x "/opt/homebrew/bin/spoofdpi" ]; then
    spoofdpi_path="/opt/homebrew/bin/spoofdpi"
  elif [ -x "/usr/local/bin/spoofdpi" ]; then
    spoofdpi_path="/usr/local/bin/spoofdpi"
  fi
  
  if [ -n "$spoofdpi_path" ]; then
    echo "spoofdpi binary bulundu: $spoofdpi_path"
    # Binary'nin çalışabilir olduğunu test et
    if "$spoofdpi_path" -h >/dev/null 2>&1; then
      echo "spoofdpi binary test edildi: OK"
    else
      warning "spoofdpi binary çalışmıyor, yeniden kuruluyor..."
      brew reinstall spoofdpi
    fi
  else
    error "spoofdpi binary bulunamadı"
    exit 1
  fi
}

setup_spoofdpi
checkmark "spoofdpi hazır"

section "Discord Kontrolü"
if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord uygulaması /Applications klasöründe bulunamadı."
  echo "Lütfen Discord'u indirip /Applications klasörüne taşıyın ve tekrar çalıştırın."
  exit 1
fi
checkmark "Discord bulundu"

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs"

mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

section "Dosyalar Kopyalanıyor"
checkmark "Betiği uygulama destek klasörüne kopyalanıyor..."
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/discord-spoofdpi.sh"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

section "launchd Servisleri"
checkmark "launchd servis dosyaları oluşturuluyor ve yükleniyor..."
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  echo "  -> $filename işleniyor..."
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  launchctl unload "$target_file" 2>/dev/null || true
  launchctl load -w "$target_file"
done

section "Kontrol Paneli"
checkmark "Kontrol paneli kuruluyor..."
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/debug-system.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/logs.sh" "$APP_SUPPORT_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/" 2>/dev/null || true
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
chmod +x "$APP_SUPPORT_DIR/debug-system.sh"
chmod +x "$APP_SUPPORT_DIR/logs.sh" 2>/dev/null || true
chmod +x "$APP_SUPPORT_DIR/SplitWire Loglar.command" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/debug-system.sh" 2>/dev/null || true
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"
LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"
rm -f "$LOGS_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$LOGS_SHORTCUT"
checkmark "Masaüstüne 'SplitWire Kontrol' kısayolu eklendi."

echo
hr
echo "${GRN}Kurulum başarıyla tamamlandı.${RST}"
echo "SplitWire Kontrol panelinden başlatabilirsiniz."