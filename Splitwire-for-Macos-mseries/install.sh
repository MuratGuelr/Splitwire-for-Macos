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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

if pgrep -x spoofdpi > /dev/null; then
    echo "✓ Servis çalışıyor"
else
    echo "! Servis başlatılamadı"
fi

# --- Kontrol Paneli'ni kopyala ---
KONTROL_FILE="$SUPPORT_DIR/SplitWire Kontrol.command"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$KONTROL_FILE"
chmod +x "$KONTROL_FILE"

# --- İZİN SORUNUNU ÇÖZMEK İÇİN ---
# Quarantine attribute'unu kaldır (izin sorunu gider)
xattr -cr "$KONTROL_FILE" 2>/dev/null || true
xattr -d com.apple.quarantine "$KONTROL_FILE" 2>/dev/null || true

# --- Masaüstü kısayolu ---
DESKTOP_FILE="$HOME/Desktop/SplitWire Kontrol.command"
cp "$KONTROL_FILE" "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"
xattr -cr "$DESKTOP_FILE" 2>/dev/null || true
xattr -d com.apple.quarantine "$DESKTOP_FILE" 2>/dev/null || true

echo "✓ Kontrol paneli oluşturuldu"

# --- DISCORD SİMGESİ AYARLA ---
echo "→ Discord simgesi ayarlanıyor..."

ICON_SOURCE="/Applications/Discord.app/Contents/Resources/electron.icns"

if [ -f "$ICON_SOURCE" ]; then
    # Python ile simge ayarla (daha güvenilir)
    python3 << PYEOF
import Cocoa
import os

icon_path = "$ICON_SOURCE"
target_path = "$DESKTOP_FILE"

try:
    image = Cocoa.NSImage.alloc().initWithContentsOfFile_(icon_path)
    if image:
        Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(image, target_path, 0)
        print("  ✓ Simge ayarlandı")
except Exception as e:
    print(f"  ! Simge ayarlanamadı: {e}")
PYEOF
fi

# Finder'ı yenile (simgenin görünmesi için)
touch "$DESKTOP_FILE"
killall Finder 2>/dev/null || true

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
echo "  Masaüstündeki 'SplitWire Kontrol' dosyasına çift tıklayın"
echo "  (Discord simgesi ile görünecek)"
echo ""
echo "  Discord Kullanımı:"
echo "  ──────────────────"
echo "  Discord'u normal açın - otomatik proxy kullanır"
echo ""