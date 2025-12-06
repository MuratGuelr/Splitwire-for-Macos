#!/usr/bin/env bash
# SplitWire Kaldırma
echo ""
echo "SplitWire kaldırılıyor..."
echo ""

# Servisi durdur
launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Dosyaları sil
rm -f "$HOME/Library/LaunchAgents/com.splitwire.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/SplitWire"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire.command"

echo "✓ Servis durduruldu"
echo "✓ Dosyalar silindi"
echo ""
echo "spoofdpi'yi de kaldırmak için: brew uninstall spoofdpi"
echo ""