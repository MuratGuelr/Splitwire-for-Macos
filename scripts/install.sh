#!/usr/bin/env bash
set -euo pipefail

# Renkler
GRN=$(tput setaf 2) YLW=$(tput setaf 3) RED=$(tput setaf 1) RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST}  $*"; }
error() { echo "${RED}✖${RST} $*"; }

spinner() {
  local pid=$1 msg=$2
  echo -n "$msg  "
  while kill -0 "$pid" 2>/dev/null; do
    for s in / - \\ \|; do echo -ne "\b$s"; sleep 0.1; done
  done
  echo -e "\b✔"
}

# ---------- Homebrew yoksa kur ----------
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew bulunamadı, kuruluyor…"
  bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-homebrew.sh" &
  spinner $! "Homebrew indiriliyor"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
checkmark "Homebrew hazır"

# ---------- Discord kontrolü ----------
if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord uygulaması /Applications klasöründe bulunamadı."
  echo "   Lütfen Discord’u indirip /Applications klasörüne taşıyın ve tekrar çalıştırın."
  exit 1
fi
checkmark "Discord bulundu"
# ----------------------------------------

PLIST_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/launchd"
PLIST_FILE="net.consolaktif.discord.spoofdpi.plist"
LAUNCHER_PLIST_FILE="net.consolaktif.discord.launcher.plist"
TARGET_PLIST="$HOME/Library/LaunchAgents/$PLIST_FILE"
TARGET_LAUNCHER_PLIST="$HOME/Library/LaunchAgents/$LAUNCHER_PLIST_FILE"

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
SCRIPT_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="discord-spoofdpi.sh"
TARGET_SCRIPT="$APP_SUPPORT_DIR/$SCRIPT_FILE"
STATE_DIR="$APP_SUPPORT_DIR/state"

mkdir -p "$HOME/Library/LaunchAgents" "$APP_SUPPORT_DIR" "$STATE_DIR"

# ---------- beklemeli launcher plist OLUŞTUR ----------
cat > "$PLIST_SRC_DIR/$LAUNCHER_PLIST_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.consolaktif.discord.launcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>-c</string>
        <string>
timeout 30 bash -c 'until lsof -i :${CD_PROXY_PORT:-8080} >/dev/null 2>&1; do sleep 0.2; done'
exec /Applications/Discord.app/Contents/MacOS/Discord --proxy-server=http://127.0.0.1:${CD_PROXY_PORT:-8080}
        </string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>HardResourceLimits</key>
    <dict>
        <key>CPU</key><integer>60</integer>
        <key>Memory</key><integer>268435456</integer>
    </dict>
</dict>
</plist>
EOF
# ------------------------------------------------------

# ana plist + script
cp "$PLIST_SRC_DIR/$PLIST_FILE" "$TARGET_PLIST"
cp "$SCRIPT_SRC_DIR/$SCRIPT_FILE" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"

# Discord proxy'li launcher
cp "$PLIST_SRC_DIR/$LAUNCHER_PLIST_FILE" "$TARGET_LAUNCHER_PLIST"

# launchd yenile
launchctl unload "$TARGET_PLIST" 2>/dev/null || true
launchctl load -w "$TARGET_PLIST"
launchctl unload "$TARGET_LAUNCHER_PLIST" 2>/dev/null || true
launchctl load -w "$TARGET_LAUNCHER_PLIST"

echo ""
checkmark "Kurulum tamam. Loglar: $HOME/Library/Logs/net.consolaktif.discord.spoofdpi.*.log"
echo "Discord otomatik olarak proxy'yi kullanacak; diğer uygulamalar etkilenmeyecek."