#!/usr/bin/env bash
# =============================================================================
# SplitWire - En Basit Kurulum
# =============================================================================
# Sadece masaüstüne bir .command dosyası koyar.
# Kullanıcı o dosyaya çift tıklayınca Discord proxy ile açılır.
# =============================================================================
set -e

echo ""
echo "SplitWire Basit Kurulum"
echo "───────────────────────"
echo ""

# Homebrew ve spoofdpi kontrol
echo "spoofdpi kontrol ediliyor..."

SPOOFDPI=""
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

if [ -z "$SPOOFDPI" ]; then
    echo "spoofdpi bulunamadı, kuruluyor..."
    
    BREW=""
    [ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
    [ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
    
    if [ -z "$BREW" ]; then
        echo "HATA: Homebrew bulunamadı!"
        echo "Kurulum: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    $BREW install spoofdpi
    
    for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
        [ -x "$p" ] && SPOOFDPI="$p" && break
    done
fi

echo "✓ spoofdpi: $SPOOFDPI"

# Discord kontrol
if [ ! -d "/Applications/Discord.app" ]; then
    echo "HATA: Discord.app bulunamadı!"
    exit 1
fi
echo "✓ Discord.app mevcut"

# Masaüstüne .command dosyası oluştur
DESKTOP="$HOME/Desktop"
CMD_FILE="$DESKTOP/Discord (Proxy).command"

cat > "$CMD_FILE" << SCRIPT
#!/bin/bash
# ═══════════════════════════════════════════════════════
#  SplitWire - Discord'u Proxy ile Başlat
# ═══════════════════════════════════════════════════════

# spoofdpi'yi bul
SPOOFDPI=""
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "\$p" ] && SPOOFDPI="\$p" && break
done

if [ -z "\$SPOOFDPI" ]; then
    osascript -e 'display alert "Hata" message "spoofdpi bulunamadı!"'
    exit 1
fi

# spoofdpi zaten çalışıyorsa öldür ve yeniden başlat
pkill -x spoofdpi 2>/dev/null
sleep 1

# spoofdpi'yi arka planda başlat
"\$SPOOFDPI" &
SPOOF_PID=\$!
sleep 2

# Port kontrol (varsayılan 8080)
PORT=8080

# Discord'u proxy ile başlat
export http_proxy="http://127.0.0.1:\$PORT"
export https_proxy="http://127.0.0.1:\$PORT"
export all_proxy="http://127.0.0.1:\$PORT"

/Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:\$PORT" &

echo ""
echo "✓ spoofdpi başlatıldı (PID: \$SPOOF_PID)"
echo "✓ Discord proxy ile açıldı"
echo ""
echo "Bu pencereyi kapatabilirsiniz."
echo "(spoofdpi arka planda çalışmaya devam edecek)"
echo ""

# Terminal'i açık tut (kullanıcı kapatana kadar)
read -p "Çıkmak için Enter'a basın..." 
pkill -x spoofdpi 2>/dev/null
SCRIPT

chmod +x "$CMD_FILE"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Masaüstünde 'Discord (Proxy).command' dosyası oluşturuldu."
echo ""
echo "  KULLANIM:"
echo "  ─────────"
echo "  1. Masaüstündeki 'Discord (Proxy)' dosyasına çift tıklayın"
echo "  2. Terminal açılacak ve Discord proxy ile başlayacak"
echo "  3. İşiniz bitince Terminal'i kapatabilirsiniz"
echo ""