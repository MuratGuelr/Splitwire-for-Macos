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
title() { hr; echo "${GRN}SplitWire • Discord Yükleyici (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

title

# Mimari kontrolü
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    warning "Bu Mac Apple Silicon (M serisi) görünüyor."
    warning "Intel versiyonu yerine 'Splitwire-for-Macos-mseries' klasörünü kullanmanız önerilir."
    read -p "Yine de devam etmek istiyor musunuz? (e/H): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ee]$ ]]; then
        exit 1
    fi
fi

# Discord zaten kurulu mu?
if [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord uygulaması zaten kurulu."
    exit 0
fi

warning "Discord uygulaması bulunamadı."
echo "Homebrew ile kuruluyor..."
echo

# Homebrew kontrolü
section "Homebrew Kontrolü"

# Intel Homebrew path'i
INTEL_HOMEBREW="/usr/local/bin/brew"
ARM_HOMEBREW="/opt/homebrew/bin/brew"

if [ -x "$INTEL_HOMEBREW" ]; then
    BREW_CMD="$INTEL_HOMEBREW"
    eval "$($INTEL_HOMEBREW shellenv)"
    checkmark "Intel Homebrew bulundu: /usr/local"
elif [ -x "$ARM_HOMEBREW" ]; then
    BREW_CMD="$ARM_HOMEBREW"
    eval "$($ARM_HOMEBREW shellenv)"
    warning "ARM Homebrew bulundu (M serisi Mac'te Intel script kullanılıyor)"
else
    warning "Homebrew bulunamadı, kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ -x "$INTEL_HOMEBREW" ]; then
        BREW_CMD="$INTEL_HOMEBREW"
        eval "$($INTEL_HOMEBREW shellenv)"
    elif [ -x "$ARM_HOMEBREW" ]; then
        BREW_CMD="$ARM_HOMEBREW"
        eval "$($ARM_HOMEBREW shellenv)"
    else
        error "Homebrew kurulumu başarısız!"
        exit 1
    fi
fi

checkmark "Homebrew hazır"

# Discord kurulumu
section "Discord Kurulumu"
echo "Bu işlem birkaç dakika sürebilir..."
echo

"$BREW_CMD" reinstall --cask discord

# Doğrulama
section "Son Doğrulama"

if [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord başarıyla kuruldu!"
    echo "Artık './install.sh' ile SplitWire kurulumuna devam edebilirsiniz."
else
    error "Discord kurulumu başarısız!"
    exit 1
fi

exit 0