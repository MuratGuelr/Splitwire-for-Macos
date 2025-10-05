#!/usr/bin/env bash
set -euo pipefail

# Sistem bilgilerini topla ve debug yap
echo "=== SplitWire Debug Bilgileri ==="
echo "Tarih: $(date)"
echo

echo "=== Mac Bilgileri ==="
echo "Mimari: $(uname -m)"
echo "İşletim Sistemi: $(uname -s)"
echo "Kernel Sürümü: $(uname -r)"
echo "macOS Sürümü: $(sw_vers -productVersion)"
echo

echo "=== Homebrew Bilgileri ==="
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew kurulu: EVET"
  echo "Homebrew sürümü: $(brew --version | head -n1)"
  echo "Homebrew prefix: $(brew --prefix)"
  echo "Homebrew PATH: $(which brew)"
else
  echo "Homebrew kurulu: HAYIR"
fi
echo

echo "=== spoofdpi Bilgileri ==="
if command -v spoofdpi >/dev/null 2>&1; then
  echo "spoofdpi kurulu: EVET"
  echo "spoofdpi yolu: $(which spoofdpi)"
  echo "spoofdpi sürümü: $(spoofdpi -h 2>&1 | head -n1 || echo 'Sürüm bilgisi alınamadı')"
else
  echo "spoofdpi kurulu: HAYIR"
fi

echo "Kontrol edilen yollar:"
for path in "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi" "/usr/bin/spoofdpi"; do
  if [ -x "$path" ]; then
    echo "  ✓ $path (çalıştırılabilir)"
  else
    echo "  ✗ $path (bulunamadı veya çalıştırılamaz)"
  fi
done
echo

echo "=== PATH Bilgileri ==="
echo "PATH: $PATH"
echo

echo "=== Discord Bilgileri ==="
if [ -d "/Applications/Discord.app" ]; then
  echo "Discord kurulu: EVET"
  echo "Discord yolu: /Applications/Discord.app"
  if [ -x "/Applications/Discord.app/Contents/MacOS/Discord" ]; then
    echo "Discord binary: Çalıştırılabilir"
  else
    echo "Discord binary: Çalıştırılamaz"
  fi
else
  echo "Discord kurulu: HAYIR"
fi
echo

echo "=== LaunchAgent Bilgileri ==="
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
if [ -d "$LAUNCH_AGENTS_DIR" ]; then
  echo "LaunchAgents klasörü: Mevcut"
  echo "SplitWire plist dosyaları:"
  for plist in "net.consolaktif.discord.spoofdpi.plist" "net.consolaktif.discord.launcher.plist"; do
    if [ -f "$LAUNCH_AGENTS_DIR/$plist" ]; then
      echo "  ✓ $plist (mevcut)"
    else
      echo "  ✗ $plist (bulunamadı)"
    fi
  done
else
  echo "LaunchAgents klasörü: Bulunamadı"
fi
echo

echo "=== Servis Durumu ==="
echo "spoofdpi servisi:"
if launchctl list | grep -q "net.consolaktif.discord.spoofdpi"; then
  echo "  Durum: Yüklü"
  launchctl list | grep "net.consolaktif.discord.spoofdpi"
else
  echo "  Durum: Yüklenmemiş"
fi

echo "launcher servisi:"
if launchctl list | grep -q "net.consolaktif.discord.launcher"; then
  echo "  Durum: Yüklü"
  launchctl list | grep "net.consolaktif.discord.launcher"
else
  echo "  Durum: Yüklenmemiş"
fi
echo

echo "=== Port Durumu ==="
echo "Port 8080 durumu:"
if lsof -i :8080 >/dev/null 2>&1; then
  echo "  Port 8080: Kullanımda"
  lsof -i :8080
else
  echo "  Port 8080: Boş"
fi
echo

echo "=== Log Dosyaları ==="
LOG_DIR="$HOME/Library/Logs"
echo "Log klasörü: $LOG_DIR"
if [ -d "$LOG_DIR" ]; then
  echo "SplitWire log dosyaları:"
  for log in "net.consolaktif.discord.spoofdpi.out.log" "net.consolaktif.discord.spoofdpi.err.log"; do
    if [ -f "$LOG_DIR/$log" ]; then
      echo "  ✓ $log (mevcut, boyut: $(wc -c < "$LOG_DIR/$log") bytes)"
    else
      echo "  ✗ $log (bulunamadı)"
    fi
  done
else
  echo "Log klasörü bulunamadı"
fi
echo

echo "=== Son Log Satırları (Hata) ==="
if [ -f "$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log" ]; then
  echo "Son 10 hata log satırı:"
  tail -n 10 "$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"
else
  echo "Hata log dosyası bulunamadı"
fi
echo

echo "=== Son Log Satırları (Çıktı) ==="
if [ -f "$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log" ]; then
  echo "Son 10 çıktı log satırı:"
  tail -n 10 "$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
else
  echo "Çıktı log dosyası bulunamadı"
fi
echo

echo "=== Test Komutları ==="
echo "spoofdpi test komutu:"
if command -v spoofdpi >/dev/null 2>&1; then
  echo "spoofdpi -h çıktısı:"
  spoofdpi -h 2>&1 | head -n 5 || echo "spoofdpi -h komutu başarısız"
else
  echo "spoofdpi komutu bulunamadı"
fi
echo

echo "=== Debug Tamamlandı ==="
echo "Bu bilgileri SplitWire geliştiricisine gönderebilirsiniz."
