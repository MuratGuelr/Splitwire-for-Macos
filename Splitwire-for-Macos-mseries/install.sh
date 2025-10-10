#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

# Görsel yardımcılar (yalnızca çıktı, davranışı değiştirmez)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Ana Kurulum (Apple Silicon)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

title

# Sadece Apple Silicon (arm64) desteklenir
if [ "$(uname -m)" != "arm64" ]; then
  error "Bu kurulum yalnızca Apple Silicon (arm64) içindir. Intel macOS desteklenmiyor."
  exit 1
fi

# 1) Xcode Komut Satırı Araçları (CLT) kontrolü ve otomatik kurulum
section "Xcode Komut Satırı Araçları"
if ! xcode-select -p >/dev/null 2>&1; then
  warning "Xcode Komut Satırı Araçları bulunamadı, kuruluyor…"
  # Önce yazılım güncellemesinden doğrudan CLT etiketini bulup kurmayı deneyelim (tamamen otomatik)
  # Bu yöntem başarısız olursa GUI ile xcode-select --install komutuna düşer ve hazır olana kadar bekleriz
  if command -v softwareupdate >/dev/null 2>&1; then
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress || true
    CLT_LABEL=$(softwareupdate -l 2>/dev/null | awk -F"*" '/Command Line Tools/ {print $2}' | sed -e 's/^ *//' -e 's/ Label: //;q' || true)
    if [ -n "${CLT_LABEL:-}" ]; then
      softwareupdate -i "$CLT_LABEL" -v || true
    fi
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress || true
  fi

  # Eğer hâlâ yoksa, GUI kurulumunu tetikle ve hazır olana kadar bekle
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    echo "Xcode Komut Satırı Araçlarının kurulumu bekleniyor (bu işlem birkaç dakika sürebilir)…"
    i=0
    # 15 dakika bekleme (90 x 10 sn)
    while ! xcode-select -p >/dev/null 2>&1; do
      sleep 10
      i=$((i+1))
      if [ "$i" -ge 90 ]; then
        error "Xcode Komut Satırı Araçları 15 dakika içinde kurulamadı. Lütfen elle kurup tekrar deneyin."
        exit 1
      fi
    done
  fi
  checkmark "Xcode Komut Satırı Araçları hazır"
else
  checkmark "Xcode Komut Satırı Araçları hazır"
fi

# 2) Homebrew (arm64) kontrolü

section "Homebrew Hazırlığı"
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew bulunamadı, kuruluyor…"
  bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    error "Homebrew ARM prefix'te bulunamadı (/opt/homebrew). Terminal'i Rosetta olmadan açıp tekrar deneyin."
    exit 1
  fi
fi
checkmark "Homebrew hazır"

# ARM Homebrew doğrula
if [ "$(brew --prefix 2>/dev/null || true)" != "/opt/homebrew" ]; then
  error "Homebrew ARM prefix'te değil (/opt/homebrew). Terminal'i Rosetta olmadan açtığınızdan emin olun."
  exit 1
fi

section "spoofdpi Kurulumu"
if ! brew list spoofdpi &>/dev/null; then
  warning "spoofdpi kurulu değil, Homebrew ile kuruluyor..."
  brew install spoofdpi
fi

# spoofdpi ikilisini bul ve arm64 olduğundan emin ol
SPOOFDPI_BIN=$(command -v spoofdpi || true)
if [ -z "${SPOOFDPI_BIN}" ] || [ ! -x "${SPOOFDPI_BIN}" ]; then
  # PATH'te değilse, arm64 brew yolunda aramayı dene
  if [ -x "/opt/homebrew/bin/spoofdpi" ]; then
    SPOOFDPI_BIN="/opt/homebrew/bin/spoofdpi"
  fi
fi

if [ -z "${SPOOFDPI_BIN}" ] || [ ! -x "${SPOOFDPI_BIN}" ]; then
  warning "spoofdpi ikilisi bulunamadı; yeniden kuruluyor…"
  brew reinstall spoofdpi
  SPOOFDPI_BIN=$(command -v spoofdpi || true)
fi

if command -v file >/dev/null 2>&1 && [ -n "${SPOOFDPI_BIN}" ]; then
  if ! file "${SPOOFDPI_BIN}" | grep -qi "arm64"; then
    warning "spoofdpi arm64 değil görünüyor, ARM olarak yeniden kuruluyor…"
    brew uninstall -f spoofdpi || true
    brew install spoofdpi
    SPOOFDPI_BIN=$(command -v spoofdpi || true)
    if [ -n "${SPOOFDPI_BIN}" ] && ! file "${SPOOFDPI_BIN}" | grep -qi "arm64"; then
      error "spoofdpi arm64 olarak kurulamadı. Terminal'i Rosetta olmadan açtığınızdan ve /opt/homebrew kullandığınızdan emin olun."
      exit 1
    fi
  fi
fi
checkmark "spoofdpi hazır (arm64)"

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
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true

# Log aracı kopyala
if [ -f "$SCRIPT_DIR/scripts/logs.sh" ]; then
  cp "$SCRIPT_DIR/scripts/logs.sh" "$APP_SUPPORT_DIR/"
  chmod +x "$APP_SUPPORT_DIR/logs.sh"
  xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/logs.sh" 2>/dev/null || true
fi
if [ -f "$SCRIPT_DIR/scripts/SplitWire Loglar.command" ]; then
  cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/"
  chmod +x "$APP_SUPPORT_DIR/SplitWire Loglar.command"
  xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Loglar.command" 2>/dev/null || true
fi
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"
checkmark "Masaüstüne 'SplitWire Kontrol' kısayolu eklendi."

# Loglar için masaüstü kısayolu (varsa)
if [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
  LOGS_SHORTCUT="$HOME/Desktop/SplitWire Loglar"
  rm -f "$LOGS_SHORTCUT"
  ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$LOGS_SHORTCUT"
  checkmark "Masaüstüne 'SplitWire Loglar' kısayolu eklendi."
fi

echo
hr
echo "${GRN}Kurulum başarıyla tamamlandı.${RST}"
echo "SplitWire Kontrol panelinden başlatabilirsiniz."