#!/usr/bin/env bash
echo "SplitWire dosyaları siliniyor..."
pkill -x spoofdpi 2>/dev/null || true
rm -f "$HOME/Desktop/Discord Başlat.command"
rm -f "$HOME/Desktop/Proxy Başlat.command"
rm -f "$HOME/Desktop/Proxy Durdur.command"
echo "✓ Tamamlandı"