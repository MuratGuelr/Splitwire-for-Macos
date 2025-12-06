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
    echo "! Servis başlatılamadı (log: $LOG_DIR/spoofdpi.log)"
fi

# --- Kontrol Paneli'ni SUPPORT_DIR'e kopyala ---
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$SUPPORT_DIR/"
chmod +x "$SUPPORT_DIR/SplitWire Kontrol.command"

# --- Masaüstüne sembolik link oluştur ---
DESKTOP_LINK="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_LINK" 2>/dev/null
ln -sf "$SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_LINK"

# --- İkon ayarla (Swift ile) ---
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    [ ! -f "$icon_path" ] && return 0
    [ ! -e "$target_file" ] && return 0

    cat > /tmp/seticon.swift << 'SWIFT'
import Cocoa
let args = CommandLine.arguments
guard args.count == 3 else { exit(1) }
if let image = NSImage(contentsOfFile: args[1]) {
    NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
}
SWIFT
    swift /tmp/seticon.swift "$icon_path" "$target_file" 2>/dev/null || true
    rm -f /tmp/seticon.swift
    touch "$target_file" 2>/dev/null || true
}

DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$DISCORD_ICON" ]; then
    echo "→ İkon ayarlanıyor..."
    set_icon "$DISCORD_ICON" "$DESKTOP_LINK"
    set_icon "$DISCORD_ICON" "$SUPPORT_DIR/SplitWire Kontrol.command"
fi

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
echo "  Masaüstündeki 'SplitWire Kontrol' dosyasını açın"
echo "  Güzel bir macOS diyaloğu görünecek:"
echo "  • Başlat / Durdur / Yeniden Başlat"
echo "  • Sistem Bilgisi"
echo "  • Bildirimler"
echo ""
echo "  Discord Kullanımı:"
echo "  ──────────────────"
echo "  Discord'u normal açın (Dock, Spotlight, Finder)"
echo "  Otomatik olarak proxy üzerinden çalışır"
echo ""