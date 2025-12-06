#!/usr/bin/env bash
# =============================================================================
# SplitWire - macOS 26 Uyumlu Kurulum
# =============================================================================
# spoofdpi'yi --system-proxy ile kullanır.
# Bu sayede Discord dahil tüm uygulamalar otomatik proxy kullanır.
# Kontrol paneli ile açıp kapatabilirsiniz.
# =============================================================================
set -e

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  SplitWire Kurulum"
echo "═══════════════════════════════════════════════════════════"
echo ""

# --- Homebrew Kontrolü ---
echo "[1/3] Homebrew kontrol ediliyor..."
BREW=""
[ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
[ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"

if [ -z "$BREW" ]; then
    echo "Homebrew bulunamadı. Kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
    [ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
fi
echo "  ✓ Homebrew: $BREW"

# --- spoofdpi Kontrolü ---
echo ""
echo "[2/3] spoofdpi kontrol ediliyor..."
eval "$($BREW shellenv)"

if ! command -v spoofdpi &>/dev/null; then
    echo "  spoofdpi kuruluyor..."
    $BREW install spoofdpi
fi
echo "  ✓ spoofdpi: $(command -v spoofdpi)"

# --- Discord Kontrolü ---
echo ""
echo "[3/3] Discord kontrol ediliyor..."
if [ ! -d "/Applications/Discord.app" ]; then
    echo "  HATA: Discord.app bulunamadı!"
    echo "  Lütfen önce Discord'u kurun: https://discord.com/download"
    exit 1
fi
echo "  ✓ Discord.app mevcut"

# --- Dosyaları Oluştur ---
echo ""
echo "Dosyalar oluşturuluyor..."

DESKTOP="$HOME/Desktop"

# ============================================
# 1. Discord'u Proxy ile Başlat
# ============================================
cat > "$DESKTOP/Discord Başlat.command" << 'SCRIPT'
#!/bin/bash
clear
echo "═══════════════════════════════════════════════════════"
echo "  SplitWire - Discord'u Proxy ile Başlat"
echo "═══════════════════════════════════════════════════════"
echo ""

# spoofdpi bul
SPOOFDPI=""
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

if [ -z "$SPOOFDPI" ]; then
    echo "HATA: spoofdpi bulunamadı!"
    echo "Kurulum: brew install spoofdpi"
    read -p "Devam etmek için Enter..."
    exit 1
fi

# Eski süreçleri temizle
pkill -x spoofdpi 2>/dev/null
pkill -x Discord 2>/dev/null
sleep 1

echo "→ spoofdpi başlatılıyor (sistem proxy aktif)..."
"$SPOOFDPI" --system-proxy &
SPOOF_PID=$!
sleep 3

# Kontrol
if ! kill -0 $SPOOF_PID 2>/dev/null; then
    echo "HATA: spoofdpi başlatılamadı!"
    read -p "Devam etmek için Enter..."
    exit 1
fi

echo "✓ spoofdpi çalışıyor (PID: $SPOOF_PID)"
echo "✓ Sistem proxy aktif"
echo ""
echo "→ Discord başlatılıyor..."
open -a Discord
sleep 2

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Discord açıldı!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Bu pencereyi AÇIK TUTUN."
echo "  Kapatınca spoofdpi durur ve proxy devre dışı kalır."
echo ""
echo "  Discord'u kapatmak için:"
echo "  1. Discord'u normal kapat"
echo "  2. Sonra bu pencereyi kapat"
echo ""
read -p "  Çıkmak için Enter'a basın..."

# Temizlik
echo ""
echo "Temizleniyor..."
pkill -x spoofdpi 2>/dev/null
echo "✓ spoofdpi durduruldu"
echo "✓ Sistem proxy devre dışı"
SCRIPT
chmod +x "$DESKTOP/Discord Başlat.command"

# ============================================
# 2. Proxy Servisi Başlat (Arka Plan)
# ============================================
cat > "$DESKTOP/Proxy Başlat.command" << 'SCRIPT'
#!/bin/bash
clear
echo "═══════════════════════════════════════════════════════"
echo "  SplitWire - Proxy Servisi Başlat"
echo "═══════════════════════════════════════════════════════"
echo ""

SPOOFDPI=""
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

if [ -z "$SPOOFDPI" ]; then
    echo "HATA: spoofdpi bulunamadı!"
    read -p "Enter..."
    exit 1
fi

pkill -x spoofdpi 2>/dev/null
sleep 1

echo "→ spoofdpi başlatılıyor..."
"$SPOOFDPI" --system-proxy &
sleep 2

if pgrep -x spoofdpi > /dev/null; then
    echo "✓ Proxy servisi çalışıyor"
    echo "✓ Sistem proxy aktif"
    echo ""
    echo "  Artık Discord'u normal şekilde açabilirsiniz."
    echo "  (Dock, Spotlight, Finder - hepsi çalışır)"
    echo ""
    echo "  Bu pencereyi AÇIK TUTUN."
    echo ""
    read -p "  Durdurmak için Enter'a basın..."
    pkill -x spoofdpi 2>/dev/null
    echo "✓ Durduruldu"
else
    echo "HATA: Başlatılamadı"
    read -p "Enter..."
fi
SCRIPT
chmod +x "$DESKTOP/Proxy Başlat.command"

# ============================================
# 3. Proxy Servisi Durdur
# ============================================
cat > "$DESKTOP/Proxy Durdur.command" << 'SCRIPT'
#!/bin/bash
echo "Proxy servisi durduruluyor..."
pkill -x spoofdpi 2>/dev/null
echo "✓ Tamamlandı"
sleep 1
SCRIPT
chmod +x "$DESKTOP/Proxy Durdur.command"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Masaüstünde 3 dosya oluşturuldu:"
echo ""
echo "  📁 Discord Başlat.command"
echo "     → spoofdpi + Discord'u birlikte başlatır"
echo "     → En kolay kullanım"
echo ""
echo "  📁 Proxy Başlat.command"
echo "     → Sadece proxy'yi başlatır"
echo "     → Discord'u istediğin yerden açabilirsin"
echo ""
echo "  📁 Proxy Durdur.command"
echo "     → Proxy'yi durdurur"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  KULLANIM:"
echo "  ─────────"
echo "  1. 'Discord Başlat' dosyasına çift tıkla"
echo "  2. Terminal açılır, Discord proxy ile başlar"
echo "  3. İşin bitince Terminal'i kapat"
echo ""