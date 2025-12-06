#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum
# =============================================================================
# - spoofdpi'yi LaunchAgent ile otomatik başlatır
# - Bilgisayar açıldığında otomatik çalışır
# - Bozulursa otomatik yeniden başlar
# - Tek dosya ile kontrol (Başlat/Durdur/Durum)
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

# --- LaunchAgent (otomatik başlatma + yeniden başlatma) ---
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

if pgrep -x spoofdpi > /dev/null; then
    echo "✓ Servis çalışıyor"
else
    echo "! Servis başlatılamadı"
fi

# --- Kontrol Paneli (tek dosya) ---
cat > "$HOME/Desktop/SplitWire.command" << 'PANEL'
#!/bin/bash
# =============================================================================
#  SplitWire Kontrol Paneli
# =============================================================================

clear

while true; do
    # Durum kontrol
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        STATUS="✅ ÇALIŞIYOR"
        PID=$(pgrep -x spoofdpi)
    else
        STATUS="❌ DURDU"
        PID="-"
    fi

    clear
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  SplitWire Kontrol Paneli"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "  Durum: $STATUS"
    echo "  PID:   $PID"
    echo ""
    echo "───────────────────────────────────────────────────────────"
    echo ""
    echo "  [1] Başlat"
    echo "  [2] Durdur"
    echo "  [3] Yeniden Başlat"
    echo "  [4] Discord Aç"
    echo "  [5] Logları Göster"
    echo "  [6] Çıkış"
    echo ""
    echo "───────────────────────────────────────────────────────────"
    echo ""
    read -p "  Seçiminiz (1-6): " choice

    case $choice in
        1)
            echo ""
            echo "  Başlatılıyor..."
            launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null
            launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
            sleep 2
            ;;
        2)
            echo ""
            echo "  Durduruluyor..."
            launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
            pkill -x spoofdpi 2>/dev/null
            sleep 1
            ;;
        3)
            echo ""
            echo "  Yeniden başlatılıyor..."
            launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
            pkill -x spoofdpi 2>/dev/null
            sleep 1
            launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null
            launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
            sleep 2
            ;;
        4)
            echo ""
            echo "  Discord açılıyor..."
            open -a Discord
            sleep 1
            ;;
        5)
            echo ""
            echo "  === LOGLAR ==="
            echo ""
            tail -20 ~/Library/Logs/SplitWire/spoofdpi.log 2>/dev/null || echo "  Log bulunamadı"
            echo ""
            read -p "  Devam için Enter..."
            ;;
        6)
            echo ""
            echo "  Çıkılıyor..."
            exit 0
            ;;
        *)
            ;;
    esac
done
PANEL
chmod +x "$HOME/Desktop/SplitWire.command"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Özellikler:"
echo "  ───────────"
echo "  ✓ spoofdpi bilgisayar açıldığında otomatik başlar"
echo "  ✓ Bozulursa otomatik yeniden başlar"
echo "  ✓ Sistem proxy aktif - Discord normal açılabilir"
echo ""
echo "  Kontrol Paneli:"
echo "  ────────────────"
echo "  Masaüstündeki 'SplitWire.command' dosyasını açın"
echo "  Buradan: Başlat / Durdur / Yeniden Başlat / Durum"
echo ""
echo "  Discord Kullanımı:"
echo "  ──────────────────"
echo "  Discord'u normal açın (Dock, Spotlight, Finder)"
echo "  Otomatik olarak proxy üzerinden çalışır"
echo ""