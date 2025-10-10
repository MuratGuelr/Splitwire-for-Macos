#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Kaldırıcı (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

title
echo "Consolaktif Discord aracı kaldırılıyor..."

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LOG_DIR="$HOME/Library/Logs"
PLIST_SPOOFDPI="net.consolaktif.discord.spoofdpi.plist"
PLIST_LAUNCHER="net.consolaktif.discord.launcher.plist"

section "Servisler Durduruluyor"
echo "Servisler durduruluyor ve kaldırılıyor..."
launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI" 2>/dev/null || true
launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER" 2>/dev/null || true
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI"
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER"

section "Discord Kapatılıyor"
echo "Discord kapatılıyor..."
osascript -e 'tell application "Discord" to quit' 2>/dev/null || true
sleep 3
# Eğer hâlâ çalışıyorsa zorla kapat
if pgrep -x "Discord" >/dev/null; then
  echo "Discord kapanmadı, zorla kapatılıyor..."
  pkill -x Discord || true
fi

section "Dosyalar Temizleniyor"
echo "Uygulama dosyaları ve kısayollar temizleniyor..."
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire Loglar"

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
hr
echo "${GRN}Kaldırma işlemi tamamlandı.${RST}"