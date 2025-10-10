#!/usr/bin/env bash
set -euo pipefail

# Diğer betiklerle uyumlu görsel fonksiyonlar
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

# Görsel yardımcılar (yalnızca çıktı, davranışı değiştirmez)
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Discord Yükleyici (Intel)${RST}"; hr; }
section() { printf "\n${YLW}▶${RST} %s\n" "$*"; }

# Bu betiğin bulunduğu klasörü bul (install-homebrew.sh'e ulaşmak için)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

title

# 1. Nihai Kontrol: Uygulama gerçekten var mı?
# Bizim için tek gerçek, dosyanın fiziksel olarak var olmasıdır.
if [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord uygulaması /Applications klasöründe zaten mevcut."
    exit 0
fi

# Eğer uygulama yoksa, kuruluma devam et
warning "Discord uygulaması /Applications klasöründe bulunamadı."
echo "Homebrew kullanılarak kurulum/onarım denenecek..."
echo

# 2. Homebrew Kontrolü ve Kurulumu
setup_homebrew_for_discord() {
  section "Homebrew Kontrolü"
  if ! command -v brew >/dev/null 2>&1; then
    warning "Homebrew bulunamadı, önce o kuruluyor…"
    bash "$SCRIPT_DIR/scripts/install-homebrew.sh"
  fi
  
  # Homebrew'u mevcut terminal oturumuna tanıt
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "Homebrew (Apple Silicon) PATH ayarlandı: /opt/homebrew"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    echo "Homebrew (Intel) PATH ayarlandı: /usr/local"
  else
    error "Homebrew kurulumu başarısız oldu"
    exit 1
  fi
  checkmark "Homebrew başarıyla kuruldu."
}

setup_homebrew_for_discord

# 3. Discord Kurulumu/Yeniden Kurulumu
echo
section "Discord Kurulumu"
warning "Discord, Homebrew ile /Applications klasörüne kuruluyor..."
echo "Bu işlem internet hızınıza bağlı olarak birkaç dakika sürebilir."

# --- DEĞİŞİKLİK: `install` yerine `reinstall` kullanıyoruz. ---
# Bu komut, Homebrew'un "zaten kurulu" demesini engeller ve
# eksik dosyaları zorla yeniden yükler.
brew reinstall --cask discord
# --- DEĞİŞİKLİK BİTTİ ---

echo
section "Son Doğrulama"
# 4. Son Doğrulama
if [ -d "/Applications/Discord.app" ]; then
    checkmark "Discord başarıyla kuruldu veya onarıldı!"
    echo "Artık ana kuruluma './install.sh' komutu ile devam edebilirsiniz."
else
    error "HATA: Discord kurulumu tamamlanmasına rağmen uygulama /Applications klasöründe bulunamadı."
    error "Lütfen Homebrew çıktısını kontrol edin veya Discord'u sitesinden elle kurmayı deneyin."
    exit 1
fi

exit 0