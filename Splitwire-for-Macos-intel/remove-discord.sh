#!/bin/bash
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
title() { echo "${RED}SplitWire • Discord Kaldırıcı (Intel)${RST}"; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

title
BREW_PATH="/usr/local"

section "Uygulama Kaldırılıyor"
if $BREW_PATH/bin/brew list --cask | grep -q "^discord$"; then
  $BREW_PATH/bin/brew uninstall --cask discord
else
  echo "⚠️ Discord Homebrew üzerinden yüklü değil."
fi

section "Kurulum Dosyası (Cache) Temizliği"
DISCORD_CACHE=$($BREW_PATH/bin/brew --cache discord 2>/dev/null)
if [ -n "$DISCORD_CACHE" ] && [ -e "$DISCORD_CACHE" ]; then
    rm -rf "$DISCORD_CACHE"
    echo "✔ Cache temizlendi."
fi
$BREW_PATH/bin/brew cleanup discord 2>/dev/null

section "Kalıntı Temizliği"
rm -rf ~/Library/Application\ Support/Discord
rm -rf ~/Library/Application\ Support/discord
rm -rf ~/Library/Preferences/com.hnc.Discord.plist
rm -rf ~/Library/Preferences/com.discordapp.Discord.plist
rm -rf ~/Library/Caches/com.hnc.Discord
rm -rf ~/Library/Caches/com.discordapp.Discord
rm -rf ~/Library/Caches/Discord
rm -rf ~/Library/Logs/Discord
rm -rf ~/Library/Saved\ Application\ State/com.hnc.Discord.savedState
rm -rf ~/Library/Saved\ Application\ State/com.discordapp.Discord.savedState

echo "${GRN}Discord tamamen silindi!${RST}"