#!/usr/bin/env bash
# SplitWire - Intel macOS
set -e

echo "SplitWire Kurulum (Intel)"
echo ""

BREW=""
[ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
[ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
[ -z "$BREW" ] && echo "Homebrew yok!" && exit 1

eval "$($BREW shellenv)"
command -v spoofdpi &>/dev/null || $BREW install spoofdpi
[ ! -d "/Applications/Discord.app" ] && echo "Discord yok!" && exit 1

DESKTOP="$HOME/Desktop"

cat > "$DESKTOP/Discord Başlat.command" << 'S'
#!/bin/bash
clear
echo "SplitWire - Discord Proxy ile Başlat"
echo ""
SPOOFDPI=""
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done
[ -z "$SPOOFDPI" ] && echo "spoofdpi yok!" && exit 1

pkill -x spoofdpi 2>/dev/null; pkill -x Discord 2>/dev/null; sleep 1
echo "→ spoofdpi başlatılıyor..."
"$SPOOFDPI" --system-proxy &
sleep 3
echo "✓ Proxy aktif"
echo "→ Discord başlatılıyor..."
open -a Discord
echo ""
echo "Bu pencereyi AÇIK TUTUN."
read -p "Çıkmak için Enter..."
pkill -x spoofdpi 2>/dev/null
echo "✓ Durduruldu"
S
chmod +x "$DESKTOP/Discord Başlat.command"

cat > "$DESKTOP/Proxy Başlat.command" << 'S'
#!/bin/bash
SPOOFDPI=""
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done
pkill -x spoofdpi 2>/dev/null; sleep 1
"$SPOOFDPI" --system-proxy &
sleep 2
echo "✓ Proxy aktif - Discord'u normal aç"
read -p "Durdurmak için Enter..."
pkill -x spoofdpi 2>/dev/null
S
chmod +x "$DESKTOP/Proxy Başlat.command"

cat > "$DESKTOP/Proxy Durdur.command" << 'S'
#!/bin/bash
pkill -x spoofdpi 2>/dev/null
echo "✓ Durduruldu"
sleep 1
S
chmod +x "$DESKTOP/Proxy Durdur.command"

echo ""
echo "✅ Kurulum tamamlandı!"
echo "Masaüstündeki 'Discord Başlat' dosyasını kullanın."