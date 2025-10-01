#!/usr/bin/env bash
set -euo pipefail

# Renkler ve yardımcı fonksiyonlar
GRN=$(tput setaf 2) YLW=$(tput setaf 3) RED=$(tput setaf 1) RST=$(tput sgr0)
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }

# BU KISIM ÖNEMLİ: Betiğin kendi bulunduğu dizini bulur.
# Bu sayede betik nereden çalıştırılırsa çalıştırılsın yollar doğru olur.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd) # Projenin ana klasörünü bulur

# ---------- Homebrew yoksa kur ----------
if ! command -v brew >/dev/null 2>&1; then
  warning "Homebrew bulunamadı, kuruluyor…"
  # install-homebrew.sh'nin aynı klasörde olduğunu varsayar
  bash "$SCRIPT_DIR/install-homebrew.sh"
  # Homebrew'un PATH'e eklenmesi için shell env'i değerlendir
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
checkmark "Homebrew hazır"

# ---------- Gerekli araçları kur (spoofdpi) ----------
if ! brew list spoofdpi &>/dev/null; then
  warning "spoofdpi kurulu değil, Homebrew ile kuruluyor..."
  brew install spoofdpi
fi
checkmark "spoofdpi hazır"

# ---------- Discord kontrolü ----------
if [[ ! -d "/Applications/Discord.app" ]]; then
  error "Discord uygulaması /Applications klasöründe bulunamadı."
  echo "Lütfen Discord'u indirip /Applications klasörüne taşıyın ve tekrar çalıştırın."
  exit 1
fi
checkmark "Discord bulundu"

# ---------- Gerekli yolları tanımla ----------
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs"

# Gerekli klasörlerin var olduğundan emin ol
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ---------- Betikleri kopyala ve çalıştırılabilir yap ----------
checkmark "Betiği uygulama destek klasörüne kopyalanıyor..."
# DÜZELTME: Artık SCRIPT_DIR doğrudan doğru yeri gösteriyor
cp "$SCRIPT_DIR/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/discord-spoofdpi.sh"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

# ---------- plist şablonlarını işle ve kopyala ----------
checkmark "launchd servis dosyaları oluşturuluyor ve yükleniyor..."
# DÜZELTME: launchd klasörüne ulaşmak için ana klasör yolu kullanılıyor
for template_file in "$PROJECT_ROOT_DIR"/launchd/*.plist.template; do
  filename=$(basename "$template_file" .template)
  target_file="$LAUNCH_AGENTS_DIR/$filename"

  echo "  -> $filename işleniyor..."
  # __USER_HOME__ yer tutucusunu gerçek ev dizini ile değiştir
  sed "s|__USER_HOME__|$HOME|g" "$template_file" > "$target_file"

  # Servisi yeniden yükle (önce durdur/kaldır, sonra yükle/başlat)
  launchctl unload "$target_file" 2>/dev/null || true
  launchctl load -w "$target_file"
done

echo
checkmark "Kurulum tamamlandı!"
echo "Discord'u başlattığınızda proxy üzerinden otomatik olarak çalışacaktır."
echo "Hata ayıklama için log dosyaları:"
echo "  $LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
echo "  $LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"