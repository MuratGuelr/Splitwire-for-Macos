#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="$HOME/Library/Logs"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
PORT_FILE="$APP_SUPPORT_DIR/.proxy_port"

print_header() {
  echo "================ SplitWire Log Aracı ================"
  echo "Log dizini: $LOG_DIR"
  echo "Out: $OUT_LOG"
  echo "Err: $ERR_LOG"
  echo "Toplam boyut: $(total_size_mb) MB"
  if [ -f "$PORT_FILE" ]; then
    echo "Mevcut port: $(cat "$PORT_FILE" 2>/dev/null)"
  fi
  echo "===================================================="
}

ensure_logs() {
  mkdir -p "$LOG_DIR"
  : > /dev/null
}

total_size_bytes() {
  local sum=0
  for f in "$OUT_LOG" "$ERR_LOG" "$OUT_LOG".*.gz "$ERR_LOG".*.gz; do
    if [ -f "$f" ]; then
      local s=$(wc -c < "$f" 2>/dev/null || echo 0)
      sum=$((sum + s))
    fi
  done
  echo "$sum"
}

total_size_mb() {
  local b=$(total_size_bytes)
  echo $((b/1024/1024))
}

menu() {
  print_header
  echo "1) Hata logunu canlı izle (tail -f err)"
  echo "2) Çıktı logunu canlı izle (tail -f out)"
  echo "3) Son 200 hata satırını göster"
  echo "4) Son 200 çıktı satırını göster"
  echo "5) Log dosyalarını Finder'da aç"
  echo "6) Logları temizle (out/err ve arşivler)"
  echo "q) Çıkış"
  read -p "Seçiminiz: " choice
  case "$choice" in
    1) ensure_logs; exec tail -f "$ERR_LOG" ;;
    2) ensure_logs; exec tail -f "$OUT_LOG" ;;
    3) ensure_logs; exec tail -n 200 "$ERR_LOG" ;;
    4) ensure_logs; exec tail -n 200 "$OUT_LOG" ;;
    5) open "$LOG_DIR"; exit 0 ;;
    6) read -p "Tüm logları silmek istediğinize emin misiniz? (y/N): " ans; if [[ "$ans" =~ ^[Yy]$ ]]; then rm -f "$OUT_LOG" "$ERR_LOG" "$OUT_LOG".* "$ERR_LOG".*; echo "Silindi."; fi; exit 0 ;;
    q|Q) exit 0 ;;
    *) echo "Geçersiz seçim"; exit 1 ;;
  esac
}

menu "$@"


