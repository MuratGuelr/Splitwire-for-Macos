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

is_empty_or_missing() {
  local f="$1"
  [ ! -f "$f" ] && return 0
  [ ! -s "$f" ] && return 0
  return 1
}

notify_and_close() {
  local msg="$1"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$msg\" with title \"SplitWire Loglar\""
    osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)' 2>/dev/null || true
  else
    echo "$msg"
  fi
  exit 0
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

do_action() {
  local choice="${1:-menu}"
  case "$choice" in
    1)
      ensure_logs
      if is_empty_or_missing "$ERR_LOG"; then notify_and_close "Hata logu bulunamadı veya boş."; fi
      exec tail -f "$ERR_LOG" ;;
    2)
      ensure_logs
      if is_empty_or_missing "$OUT_LOG"; then notify_and_close "Çıktı logu bulunamadı veya boş."; fi
      exec tail -f "$OUT_LOG" ;;
    3)
      ensure_logs
      if is_empty_or_missing "$ERR_LOG"; then notify_and_close "Hata logu bulunamadı veya boş."; fi
      tail -n 200 "$ERR_LOG"; exit 0 ;;
    4)
      ensure_logs
      if is_empty_or_missing "$OUT_LOG"; then notify_and_close "Çıktı logu bulunamadı veya boş."; fi
      tail -n 200 "$OUT_LOG"; exit 0 ;;
    5)
      open "$LOG_DIR"; exit 0 ;;
    6)
      read -p "Tüm logları silmek istediğinize emin misiniz? (y/N): " ans; if [[ "$ans" =~ ^[Yy]$ ]]; then rm -f "$OUT_LOG" "$ERR_LOG" "$OUT_LOG".* "$ERR_LOG".*; echo "Silindi."; fi; exit 0 ;;
    menu|*)
      ;;
  esac
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
  do_action "$choice"
  exit 0
}

# Argüman verilmişse doğrudan uygula (1..6), yoksa menüyü göster
if [[ "${1:-}" =~ ^[1-6]$ ]]; then
  do_action "$1"
else
  menu
fi


