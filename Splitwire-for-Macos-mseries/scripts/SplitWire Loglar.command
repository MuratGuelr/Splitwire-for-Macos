#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOG_DIR="$HOME/Library/Logs"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

is_empty_or_missing() {
  local f="$1"
  [ ! -f "$f" ] && return 0
  [ ! -s "$f" ] && return 0
  return 1
}

USER_CHOICE=$(osascript <<'APPLESCRIPT'
try
  set optionsList to {"Finder'da Aç", "Canlı Log (tail -f)", "Son 200 Çıktı"}
  set theChoice to choose from list optionsList with title "SplitWire" with prompt "Log işlemi seçin" OK button name "Seç" cancel button name "İptal" without multiple selections allowed and empty selection allowed
  if theChoice is false then return "İptal"
  return (item 1 of theChoice)
on error number -128
  return "İptal"
end try
APPLESCRIPT
)

case "$USER_CHOICE" in
  "Finder'da Aç")
    open "$LOG_DIR"
    osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
    exit 0 ;;
  "Canlı Log (tail -f)")
    if is_empty_or_missing "$ERR_LOG" && is_empty_or_missing "$OUT_LOG"; then
      osascript -e 'display notification "Log bulunamadı veya boş." with title "SplitWire Loglar"'
      osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
      exit 0
    fi
    TARGET="$ERR_LOG"
    if is_empty_or_missing "$ERR_LOG"; then TARGET="$OUT_LOG"; fi
    exec bash -lc "tail -f \"$TARGET\"" ;;
  "Son 200 Çıktı")
    if is_empty_or_missing "$OUT_LOG"; then
      osascript -e 'display notification "Çıktı logu bulunamadı veya boş." with title "SplitWire Loglar"'
      osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
      exit 0
    fi
    exec bash -lc "tail -n 200 \"$OUT_LOG\" | less" ;;
  *)
    osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
    exit 0 ;;
esac
