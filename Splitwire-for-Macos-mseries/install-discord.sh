#!/usr/bin/env bash
set -euo pipefail

# Görsel fonksiyonlar
GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Discord Yükleyici (Apple Silicon)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

title

# Mimari kontrolü - SADECE ARM64
if [ "$(uname -m)" != "arm64" ]; then
    error "Bu kurulum yalnızca Apple Silicon (M1/M2/M3/M4) içindir."
    error "Intel Mac için 'Splitwire-for-Macos-intel' klasörünü kullanın."
    exit 1
fi

# Discord zaten kurulu mu kontrol et
if [ -d "/Applications/Discord.app" ]; then
    # Mimari kontrolü - ARM64 mi yoksa Intel mi?
    DISCORD_ARCH=$(file /Applications/Discord.app/Contents/MacOS/Discord 2>/dev/null | grep -o 'arm64\|x86_64' | head -1)
    
    if [ "$DISCORD_ARCH" = "arm64" ]; then
        checkmark "Discord (Apple Silicon) zaten kurulu."
        exit 0
    else
        warning "Mevcut Discord Intel versiyonu! ARM64 versiyonu kuruluyor..."
        rm -rf /Applications/Discord.app
    fi
fi

warning "Discord uygulaması bulunamadı veya yanlış mimari."
echo "Apple Silicon (ARM64) versiyonu kuruluyor..."
echo

# Homebrew kontrolü - ARM Homebrew OLMALI
section "Homebrew Kontrolü"

# ARM Homebrew path'i
HOMEBREW_PATH="/opt/homebrew"

if [ ! -x "$HOMEBREW_PATH/bin/brew" ]; then
    warning "ARM Homebrew bulunamadı, kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ARM Homebrew'u aktif et
eval "$($HOMEBREW_PATH/bin/brew shellenv)"

# Doğrulama
if [ "$(brew --prefix 2>/dev/null)" != "$HOMEBREW_PATH" ]; then
    error "Homebrew ARM prefix'te değil!"
    error "Terminal'i Rosetta olmadan açtığınızdan emin olun."
    exit 1
fi

checkmark "Homebrew (ARM) hazır: $HOMEBREW_PATH"

# Discord kurulumu
section "Discord Kurulumu (ARM64)"
echo "Bu işlem internet hızınıza bağlı olarak birkaç dakika sürebilir."
echo

# ARM Homebrew ile kur (Intel Homebrew değil!)
"$HOMEBREW_PATH/bin/brew" reinstall --cask discord

# Doğrulama
section "Son Doğrulama"

if [ -d "/Applications/Discord.app" ]; then
    DISCORD_ARCH=$(file /Applications/Discord.app/Contents/MacOS/Discord 2>/dev/null | grep -o 'arm64\|x86_64' | head -1)
    
    if [ "$DISCORD_ARCH" = "arm64" ]; then
        checkmark "Discord (Apple Silicon - ARM64) başarıyla kuruldu!"
        echo "Artık './install.sh' ile SplitWire kurulumuna devam edebilirsiniz."
    else
        warning "Discord kuruldu ama Intel versiyonu görünüyor."
        warning "Manuel olarak discord.com'dan ARM versiyonunu indirin."
    fi
else
    error "Discord kurulumu başarısız!"
    exit 1
fi

exit 0