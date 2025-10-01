#!/usr/bin/env bash
set -euo pipefail

# Diğer betiklerle uyumlu görsel fonksiyonlar
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }

# Bu betiğin bulunduğu klasörü bul (install-homebrew.sh'e ulaşmak için)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 1. Homebrew Kontrolü
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew bulunamadı, önce o kuruluyor…"
  bash "$SCRIPT_DIR/install-homebrew.sh"
  
  # Homebrew'u mevcut terminal oturumuna tanıt
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  checkmark "Homebrew başarıyla kuruldu."
else
  checkmark "Homebrew zaten kurulu."
fi

# 2. Discord Kontrolü
if brew list --cask discord &>/dev/null || [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord zaten kurulu, işlem yapılmadı."
    exit 0
fi

# 3. Discord Kurulumu
echo
warning "Discord, Homebrew ile /Applications klasörüne kuruluyor..."
echo "Bu işlem internet hızınıza bağlı olarak birkaç dakika sürebilir."

brew install --cask discord

echo
if [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord başarıyla kuruldu!"
    echo "Artık ana kuruluma './install.sh' komutu ile devam edebilirsiniz."
else
    error "Discord kurulumu tamamlandı ancak uygulama bulunamadı. Lütfen durumu kontrol edin."
    exit 1
fi

exit 0