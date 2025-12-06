#!/usr/bin/env bash
set -e

echo ""
echo "SplitWire Kaldırma"
echo "──────────────────"
echo ""

read -p "SplitWire'ı kaldırmak istiyor musunuz? (y/N): " c
if [[ ! "$c" =~ ^[Yy]$ ]]; then
    echo "İptal edildi."
    exit 0
fi

echo ""
echo "Kaldırılıyor..."

# Servis durdur
launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Dosyaları sil
rm -f "$HOME/Library/LaunchAgents/com.splitwire.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/SplitWire"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -rf "/Applications/SplitWire Discord.app"

# Eski dosyalar (varsa)
launchctl bootout gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null || true
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.spoofdpi.plist"
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/Consolaktif-Discord"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"

echo "✓ SplitWire kaldırıldı"

# spoofdpi
if command -v brew &>/dev/null && brew list spoofdpi &>/dev/null; then
    echo ""
    read -p "spoofdpi'yi de kaldırmak ister misiniz? (y/N): " s
    if [[ "$s" =~ ^[Yy]$ ]]; then
        brew uninstall spoofdpi
        echo "✓ spoofdpi kaldırıldı"
    fi
fi

echo ""
echo "Tamamlandı. Discord normal şekilde kullanılabilir."
echo ""