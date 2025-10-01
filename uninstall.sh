#!/usr/bin/env bash
set -euo pipefail

echo "Consolaktif Discord aracı kaldırılıyor..."

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LOG_DIR="$HOME/Library/Logs"
PLIST_SPOOFDPI="net.consolaktif.discord.spoofdpi.plist"
PLIST_LAUNCHER="net.consolaktif.discord.launcher.plist"

echo "Servisler durduruluyor ve kaldırılıyor..."
launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI" 2>/dev/null || true
launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER" 2>/dev/null || true
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI"
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER"

pkill -x Discord || true
sleep 1

echo "Uygulama dosyaları ve kısayollar temizleniyor..."
rm -f "$HOME/Desktop/SplitWire Kontrol"

echo
read -p "Uygulama destek dosyalarını (kontrol paneli dahil) ve logları da silmek ister misiniz? (y/n): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  rm -rf "$APP_SUPPORT_DIR"
  rm -f "$LOG_DIR/net.consolaktif.discord.spoofdpi"*
  echo "Destek dosyaları ve loglar silindi."
fi

read -p "Homebrew ile kurulan 'spoofdpi' paketini de kaldırmak ister misiniz? (y/n): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  if command -v brew >/dev/null 2>&1 && brew list spoofdpi &>/dev/null; then
    brew uninstall spoofdpi
    echo "'spoofdpi' kaldırıldı."
  else
    echo "'spoofdpi' kurulu değil veya Homebrew bulunamadı."
  fi
fi

echo
echo "Kaldırma işlemi tamamlandı."