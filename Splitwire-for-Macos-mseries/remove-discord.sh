#!/bin/bash

# Görsel yardımcılar (yalnızca çıktı, davranışı değiştirmez)
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Discord Kaldırıcı (Apple Silicon)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }
checkmark() { echo "${GRN}✔${RST} $*"; }

title
echo "🧹 Discord (Apple Silicon) kaldırma işlemi başlatılıyor..."

# Homebrew dizini (Apple Silicon)
BREW_PATH="/opt/homebrew"

section "Homebrew Üzerinden Kaldırma"
# Discord Homebrew üzerinden yüklüyse kaldır
if $BREW_PATH/bin/brew list --cask | grep -q "^discord$"; then
  echo "📦 Discord Homebrew üzerinden kaldırılıyor..."
  $BREW_PATH/bin/brew uninstall --cask discord
else
  echo "⚠️ Discord Homebrew üzerinden yüklü görünmüyor, manuel temizlik yapılıyor..."
fi

section "Kalıntı Dosyaların Temizliği"
# Discord kalıntı dosyaları
echo "🗑️ Discord sistem dosyaları temizleniyor..."
rm -rf ~/Library/Application\ Support/Discord
rm -rf ~/Library/Preferences/com.hnc.Discord.plist
rm -rf ~/Library/Preferences/com.discordapp.Discord.plist
rm -rf ~/Library/Preferences/com.discord.helper.plist
rm -rf ~/Library/Caches/com.hnc.Discord
rm -rf ~/Library/Caches/com.discordapp.Discord
rm -rf ~/Library/Logs/Discord
rm -rf ~/Library/Saved\ Application\ State/com.hnc.Discord.savedState
rm -rf ~/Library/Saved\ Application\ State/com.discordapp.Discord.savedState

section "Homebrew Temizliği"
# Homebrew cleanup
echo "🧼 Homebrew önbelleği temizleniyor..."
$BREW_PATH/bin/brew cleanup

hr
checkmark "Discord (Apple Silicon) başarıyla tamamen kaldırıldı!"
