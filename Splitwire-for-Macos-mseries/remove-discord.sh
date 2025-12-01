#!/bin/bash

# Görsel yardımcılar
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Discord Kaldırıcı (Apple Silicon)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }
checkmark() { echo "${GRN}✔${RST} $*"; }

title
echo "🧹 Discord (Apple Silicon) kaldırma işlemi başlatılıyor..."

# Homebrew dizini (Apple Silicon)
BREW_PATH="/opt/homebrew"

# 1. Homebrew Üzerinden Kaldırma
section "Uygulama Kaldırılıyor"
if $BREW_PATH/bin/brew list --cask | grep -q "^discord$"; then
  echo "📦 Discord Homebrew üzerinden kaldırılıyor..."
  $BREW_PATH/bin/brew uninstall --cask discord
else
  echo "⚠️ Discord Homebrew üzerinden yüklü görünmüyor, manuel temizlik yapılıyor..."
fi

# 2. Kurulum Dosyası (Cache) Temizliği - KRİTİK KISIM
section "Bozuk İndirme Dosyası (Cache) Temizliği"
echo "🧼 Homebrew'un hafızasındaki eski kurulum dosyası (.dmg) siliniyor..."

# Homebrew'un Discord için indirdiği dosyanın yolunu bul ve sil
DISCORD_CACHE=$($BREW_PATH/bin/brew --cache discord 2>/dev/null)
if [ -n "$DISCORD_CACHE" ] && [ -e "$DISCORD_CACHE" ]; then
    rm -rf "$DISCORD_CACHE"
    echo "   -> Cache dosyası başarıyla silindi."
else
    echo "   -> Cache dosyası zaten yok."
fi

# Homebrew genel temizlik
$BREW_PATH/bin/brew cleanup discord 2>/dev/null

# 3. Kalıntı Dosyaların Temizliği
section "Sistem ve Ayar Dosyalarının Temizliği"
echo "🗑️ Discord sistem dosyaları temizleniyor..."

# Application Support (Hem büyük hem küçük harf kontrolü)
rm -rf ~/Library/Application\ Support/Discord
rm -rf ~/Library/Application\ Support/discord

# Tercihler
rm -rf ~/Library/Preferences/com.hnc.Discord.plist
rm -rf ~/Library/Preferences/com.discordapp.Discord.plist
rm -rf ~/Library/Preferences/com.discord.helper.plist

# Önbellekler
rm -rf ~/Library/Caches/com.hnc.Discord
rm -rf ~/Library/Caches/com.hnc.Discord.ShipIt
rm -rf ~/Library/Caches/com.discordapp.Discord
rm -rf ~/Library/Caches/Discord

# Loglar ve Durumlar
rm -rf ~/Library/Logs/Discord
rm -rf ~/Library/Saved\ Application\ State/com.hnc.Discord.savedState
rm -rf ~/Library/Saved\ Application\ State/com.discordapp.Discord.savedState

hr
checkmark "Discord tamamen silindi!"