#!/usr/bin/env bash
echo "Discord (Proxy).command dosyası siliniyor..."
rm -f "$HOME/Desktop/Discord (Proxy).command"
pkill -x spoofdpi 2>/dev/null || true
echo "✓ Tamamlandı"