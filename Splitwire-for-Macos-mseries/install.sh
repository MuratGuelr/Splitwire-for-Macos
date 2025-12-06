#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - Minimal Müdahale (macOS 26 Uyumlu)
# =============================================================================
# Bu script Discord'a minimum müdahale ile proxy yapılandırması yapar.
# Yalnızca Info.plist'e LSEnvironment ekler ve uygulamayı imzalar.
# Discord'un kendisi (binary) DEĞİŞMEZ.
#
# Nereden açarsanız açın (Dock, Spotlight, Finder) proxy ile çalışır!
# =============================================================================
set -euo pipefail

# Renkler
GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Minimal Kurulum${RST}"; hr; }

title

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Mimari tespiti
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
    HOMEBREW_PATH="/opt/homebrew"
else
    HOMEBREW_PATH="/usr/local"
fi

# Klasörler
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# BAĞIMLILIKLAR
# ----------------------------------------------------------------------
echo "Bağımlılıklar kontrol ediliyor..."

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
    if [ -x "$HOMEBREW_PATH/bin/brew" ]; then
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    else
        error "Homebrew bulunamadı!"
        exit 1
    fi
fi

# spoofdpi
if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kuruluyor..."
    brew install spoofdpi
fi
checkmark "spoofdpi hazır"

# Discord kontrolü
DISCORD_APP="/Applications/Discord.app"
DISCORD_PLIST="$DISCORD_APP/Contents/Info.plist"

if [ ! -d "$DISCORD_APP" ]; then
    error "Discord.app bulunamadı!"
    exit 1
fi
checkmark "Discord.app mevcut"

# ----------------------------------------------------------------------
# ESKİ KURULUMLARI TEMİZLE
# ----------------------------------------------------------------------
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Eski wrapper varsa geri al
if [ -d "/Applications/Discord_Original.app" ]; then
    rm -rf "$DISCORD_APP"
    mv "/Applications/Discord_Original.app" "$DISCORD_APP"
    checkmark "Discord orijinal haline getirildi"
fi

# SplitWire Discord varsa sil
rm -rf "/Applications/SplitWire Discord.app" 2>/dev/null || true

# ----------------------------------------------------------------------
# SPOOFDPI SERVİSİ
# ----------------------------------------------------------------------
echo "Proxy servisi yapılandırılıyor..."

cat > "$APP_SUPPORT_DIR/spoofdpi-service.sh" << 'EOF'
#!/bin/bash
for path in "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi"; do
    if [ -x "$path" ]; then
        exec "$path" --listen-addr 127.0.0.1 --listen-port 8080 --enable-doh --window-size 0
    fi
done
echo "spoofdpi bulunamadı" >&2
exit 1
EOF
chmod +x "$APP_SUPPORT_DIR/spoofdpi-service.sh"

cat > "$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.consolaktif.discord.spoofdpi</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_SUPPORT_DIR/spoofdpi-service.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/spoofdpi.out.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/spoofdpi.err.log</string>
</dict>
</plist>
EOF

launchctl load -w "$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist"
sleep 2

if pgrep -x "spoofdpi" >/dev/null; then
    checkmark "Proxy servisi çalışıyor"
else
    warning "Proxy servisi başlatılamadı"
fi

# ----------------------------------------------------------------------
# DISCORD INFO.PLIST YAPILANDIRMASI (LSEnvironment)
# ----------------------------------------------------------------------
echo "Discord yapılandırılıyor..."
echo "${YLW}Şifreniz istenecek (Discord dosyalarını değiştirmek için):${RST}"

# sudo yetkisi al
sudo -v

# Orijinal plist'i yedekle
BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
if [ ! -f "$BACKUP_PLIST" ]; then
    sudo cp "$DISCORD_PLIST" "$BACKUP_PLIST"
    sudo chown $(whoami) "$BACKUP_PLIST"
    checkmark "Orijinal Info.plist yedeklendi"
fi

# LSEnvironment ekle/güncelle
echo "  -> LSEnvironment ekleniyor..."

# Geçici dosyaya yaz, sonra sudo ile kopyala
TEMP_PLIST="/tmp/discord_info_plist_temp.plist"

python3 << PYEOF
import plistlib

plist_path = "$DISCORD_PLIST"
temp_path = "$TEMP_PLIST"

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

# LSEnvironment ekle
plist['LSEnvironment'] = {
    'http_proxy': 'http://127.0.0.1:8080',
    'https_proxy': 'http://127.0.0.1:8080',
    'HTTP_PROXY': 'http://127.0.0.1:8080',
    'HTTPS_PROXY': 'http://127.0.0.1:8080',
    'all_proxy': 'http://127.0.0.1:8080',
    'ALL_PROXY': 'http://127.0.0.1:8080'
}

with open(temp_path, 'wb') as f:
    plistlib.dump(plist, f)
PYEOF

# sudo ile kopyala
sudo cp "$TEMP_PLIST" "$DISCORD_PLIST"
rm -f "$TEMP_PLIST"
echo "  -> LSEnvironment eklendi"

# Uygulamayı yeniden imzala (macOS 26 için gerekli)
echo "  -> Uygulama imzalanıyor..."
sudo codesign --force --deep --sign - "$DISCORD_APP" 2>/dev/null || {
    warning "Ad-hoc imzalama başarısız, alternatif yöntem deneniyor..."
    sudo xattr -cr "$DISCORD_APP"
}

# Quarantine attribute'u kaldır
sudo xattr -dr com.apple.quarantine "$DISCORD_APP" 2>/dev/null || true

# LaunchServices cache'i temizle
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true

checkmark "Discord yapılandırıldı"

# Kontrol scripti
cat > "$APP_SUPPORT_DIR/control.sh" << 'CTRL_EOF'
#!/bin/bash
case "${1:-}" in
    start)
        launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist 2>/dev/null
        launchctl kickstart gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null
        echo "Servis başlatıldı"
        ;;
    stop)
        launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null
        pkill -x spoofdpi 2>/dev/null
        echo "Servis durduruldu"
        ;;
    status)
        if pgrep -x "spoofdpi" >/dev/null; then echo "Aktif"; else echo "Pasif"; fi
        ;;
    restore)
        # Discord'u orijinal haline getir
        BACKUP="$HOME/Library/Application Support/Consolaktif-Discord/Info.plist.backup"
        if [ -f "$BACKUP" ]; then
            cp "$BACKUP" "/Applications/Discord.app/Contents/Info.plist"
            codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null || true
            echo "Discord orijinal haline getirildi"
        else
            echo "Yedek bulunamadı"
        fi
        ;;
    *) echo "Kullanım: $0 {start|stop|status|restore}" ;;
esac
CTRL_EOF
chmod +x "$APP_SUPPORT_DIR/control.sh"

# ----------------------------------------------------------------------
# TAMAMLANDI
# ----------------------------------------------------------------------
echo
hr
echo "${GRN}✅ KURULUM TAMAMLANDI!${RST}"
hr
echo
echo "📋 ${YLW}NE DEĞİŞTİ:${RST}"
echo "   • Discord'un Info.plist dosyasına proxy ayarları eklendi"
echo "   • Uygulama yeniden imzalandı (macOS 26 uyumu)"
echo "   • spoofdpi arka planda çalışıyor"
echo
echo "🚀 ${YLW}KULLANIM:${RST}"
echo "   • Discord'u her zamanki gibi açın (Dock, Spotlight, Finder)"
echo "   • Otomatik olarak proxy üzerinden çalışacak"
echo "   • Diğer uygulamalar ETKİLENMEZ"
echo
echo "🔧 ${YLW}KONTROL:${RST}"
echo "   • ~/Library/Application Support/Consolaktif-Discord/control.sh"
echo "   • control.sh restore - Discord'u orijinal haline getirir"
echo
echo "⚠️  ${YLW}NOT:${RST}"
echo "   Discord güncellenirse bu işlemi tekrar yapmanız gerekebilir."
echo