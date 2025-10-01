#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew bulunamadı, kuruluyor…"
  bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
checkmark "Homebrew hazır"

if ! brew list spoofdpi &>/dev/null; then
  warning "spoofdpi kurulu değil, Homebrew ile kuruluyor..."
  brew install spoofdpi
fi
checkmark "spoofdpi hazır"

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

checkmark "Betiği uygulama destek klasörüne kopyalanıyor..."
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/discord-spoofdpi.sh"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

checkmark "launchd servis dosyaları oluşturuluyor ve yükleniyor..."
for template_file in "$SCRIPT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"
  echo "  -> $filename işleniyor..."
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"
  launchctl unload "$target_file" 2>/dev/null || true
  launchctl load -w "$target_file"
done

checkmark "Kontrol paneli kuruluyor..."
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/control.sh"
chmod +x "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/control.sh" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR/SplitWire Kontrol.command" 2>/dev/null || true
DESKTOP_SHORTCUT="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_SHORTCUT"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_SHORTCUT"
checkmark "Masaüstüne 'SplitWire Kontrol' kısayolu eklendi."

echo
echo "Kurulum tamamlandı. Proxy servisinin başlaması bekleniyor..."
i=0
while ! lsof -i :${CD_PROXY_PORT:-8080} &>/dev/null; do
    sleep 0.5
    i=$((i+1))
    if [ "$i" -ge 20 ]; then # 10 saniye bekle
        error "Proxy servisi 10 saniye içinde başlayamadı. Logları kontrol edin."
        exit 1
    fi
done
checkmark "Proxy servisi aktif. Discord başlatılıyor..."
launchctl start net.consolaktif.discord.launcher

# --- YENİ: Başarılı kurulum sonrası kullanıcıyı bilgilendir ve terminali kapat ---
SUCCESS_MESSAGE="SplitWire kurulumu başarıyla tamamlandı! Discord şimdi başlatılıyor."
osascript -e "display dialog \"$SUCCESS_MESSAGE\" with title \"Kurulum Başarılı\" buttons {\"Tamam\"} default button \"Tamam\" with icon note"

# AppleScript ile ön plandaki terminal penceresini kapat
osascript -e 'tell application "Terminal" to close (first window whose frontmost is true)' &> /dev/null
# --- BİTTİ ---