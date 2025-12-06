#!/usr/bin/env bash
# Intel versiyonu - aynı basit kurulum
set -e

echo "SplitWire Basit Kurulum (Intel)"

SPOOFDPI=""
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

if [ -z "$SPOOFDPI" ]; then
    echo "spoofdpi kuruluyor..."
    BREW=""
    [ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
    [ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
    [ -z "$BREW" ] && echo "Homebrew yok!" && exit 1
    $BREW install spoofdpi
    for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
        [ -x "$p" ] && SPOOFDPI="$p" && break
    done
fi

echo "✓ spoofdpi: $SPOOFDPI"
[ ! -d "/Applications/Discord.app" ] && echo "Discord yok!" && exit 1
echo "✓ Discord.app"

cat > "$HOME/Desktop/Discord (Proxy).command" << 'SCRIPT'
#!/bin/bash
SPOOFDPI=""
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done
[ -z "$SPOOFDPI" ] && osascript -e 'display alert "Hata" message "spoofdpi bulunamadı!"' && exit 1

pkill -x spoofdpi 2>/dev/null; sleep 1
"$SPOOFDPI" &
sleep 2

export http_proxy="http://127.0.0.1:8080" https_proxy="http://127.0.0.1:8080" all_proxy="http://127.0.0.1:8080"
/Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:8080" &

echo "✓ Discord proxy ile açıldı"
read -p "Çıkmak için Enter..."
pkill -x spoofdpi 2>/dev/null
SCRIPT

chmod +x "$HOME/Desktop/Discord (Proxy).command"
echo ""
echo "✅ Masaüstünde 'Discord (Proxy).command' oluşturuldu."
echo "   Çift tıklayarak Discord'u proxy ile açabilirsiniz."