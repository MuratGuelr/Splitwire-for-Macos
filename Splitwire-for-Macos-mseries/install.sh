#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum
# =============================================================================
set -e

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  SplitWire Kurulum"
echo "═══════════════════════════════════════════════════════════"
echo ""

# --- Homebrew ---
BREW=""
[ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
[ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"

if [ -z "$BREW" ]; then
    echo "Homebrew kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
    [ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
fi
echo "✓ Homebrew"

# --- spoofdpi ---
eval "$($BREW shellenv)"
if ! command -v spoofdpi &>/dev/null; then
    echo "spoofdpi kuruluyor..."
    $BREW install spoofdpi
fi
SPOOFDPI_PATH=$(command -v spoofdpi)
echo "✓ spoofdpi: $SPOOFDPI_PATH"

# --- Discord ---
[ ! -d "/Applications/Discord.app" ] && echo "Discord bulunamadı!" && exit 1
echo "✓ Discord"

# --- Klasörler ---
SUPPORT_DIR="$HOME/Library/Application Support/SplitWire"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/SplitWire"
mkdir -p "$SUPPORT_DIR" "$AGENTS_DIR" "$LOG_DIR"

# --- Eski servisi temizle ---
launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
sleep 1

# --- spoofdpi başlatma scripti ---
cat > "$SUPPORT_DIR/run-spoofdpi.sh" << SCRIPT
#!/bin/bash
exec "$SPOOFDPI_PATH" --system-proxy 2>&1
SCRIPT
chmod +x "$SUPPORT_DIR/run-spoofdpi.sh"

# --- LaunchAgent ---
cat > "$AGENTS_DIR/com.splitwire.spoofdpi.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.splitwire.spoofdpi</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SUPPORT_DIR/run-spoofdpi.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
</dict>
</plist>
PLIST

# --- Servisi başlat ---
launchctl load -w "$AGENTS_DIR/com.splitwire.spoofdpi.plist"
sleep 2

# --- Kontrol Paneli (macOS Native GUI) ---
cat > "$HOME/Desktop/SplitWire.command" << 'PANEL'
#!/bin/bash
# =============================================================================
#  SplitWire Kontrol Paneli - macOS Native GUI
# =============================================================================

# Fonksiyonlar
get_status() {
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        echo "✅ Çalışıyor (PID: $(pgrep -x spoofdpi))"
    else
        echo "❌ Durdu"
    fi
}

show_notification() {
    osascript -e "display notification \"$1\" with title \"SplitWire\" sound name \"Pop\""
}

start_service() {
    launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null
    launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    sleep 2
    if pgrep -x spoofdpi > /dev/null; then
        show_notification "Proxy servisi başlatıldı"
    else
        show_notification "Servis başlatılamadı!"
    fi
}

stop_service() {
    launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    pkill -x spoofdpi 2>/dev/null
    sleep 1
    show_notification "Proxy servisi durduruldu"
}

restart_service() {
    stop_service
    sleep 1
    start_service
}

open_discord() {
    open -a Discord
    show_notification "Discord açıldı"
}

show_logs() {
    LOG_FILE=~/Library/Logs/SplitWire/spoofdpi.log
    if [ -f "$LOG_FILE" ]; then
        osascript -e "
            set logContent to do shell script \"tail -30 '$LOG_FILE' 2>/dev/null || echo 'Log boş'\"
            display dialog logContent with title \"SplitWire Logları\" buttons {\"Tamam\"} default button 1 with icon note
        " 2>/dev/null
    else
        osascript -e 'display alert "Log Bulunamadı" message "Henüz log dosyası oluşmamış."'
    fi
}

# Ana Menü Döngüsü
while true; do
    STATUS=$(get_status)
    
    CHOICE=$(osascript -e "
        set theChoice to button returned of (display dialog \"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               SplitWire Kontrol Paneli
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Durum: $STATUS

Discord'u normal şekilde açabilirsiniz.
Proxy otomatik olarak aktif.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\" with title \"SplitWire\" buttons {\"Çıkış\", \"Loglar\", \"Discord Aç\", \"Yeniden Başlat\", \"Durdur\", \"Başlat\"} default button \"Discord Aç\" with icon note)
    " 2>/dev/null)
    
    case "$CHOICE" in
        "Başlat") start_service ;;
        "Durdur") stop_service ;;
        "Yeniden Başlat") restart_service ;;
        "Discord Aç") open_discord ;;
        "Loglar") show_logs ;;
        "Çıkış"|"") exit 0 ;;
    esac
done
PANEL
chmod +x "$HOME/Desktop/SplitWire.command"

# --- İkon ayarla (Discord ikonu) ---
ICON_SOURCE="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$ICON_SOURCE" ]; then
    # fileicon aracı varsa kullan, yoksa devam et
    if command -v fileicon &>/dev/null; then
        fileicon set "$HOME/Desktop/SplitWire.command" "$ICON_SOURCE" 2>/dev/null || true
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Masaüstündeki 'SplitWire.command' dosyasını açın."
echo "  Güzel bir macOS diyaloğu görünecek."
echo ""
echo "  Discord'u normal açabilirsiniz - otomatik proxy kullanır."
echo ""