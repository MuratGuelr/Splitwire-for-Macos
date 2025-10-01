#!/usr/bin/env bash
set -euo pipefail

# Diğer betiklerle uyumlu görsel fonksiyonlar
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

# Bu betiğin bulunduğu klasörü bul (install-homebrew.sh'e ulaşmak için)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

# 3. Discord Kurulumu/Yeniden Kurulumu
echo
warning "Discord, Homebrew ile /Applications klasörüne kuruluyor..."
echo "Bu işlem internet hızınıza bağlı olarak birkaç dakika sürebilir."

# --- DEĞİŞİKLİK: `install` yerine `reinstall` kullanıyoruz. ---
# Bu komut, Homebrew'un "zaten kurulu" demesini engeller ve
# eksik dosyaları zorla yeniden yükler.
brew reinstall --cask discord
# --- DEĞİŞİKLİK BİTTİ ---

echo
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