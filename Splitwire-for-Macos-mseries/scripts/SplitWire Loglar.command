#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
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
  set dlg to display dialog "Log işlemi seçin" with title "SplitWire" buttons {"Finder'da Aç", "Son Hatalar", "Canlı Hata Logları"} default button "Son Hatalar"
  return button returned of dlg
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
  "Canlı Hata Logları")
    if is_empty_or_missing "$ERR_LOG" && is_empty_or_missing "$OUT_LOG"; then
      osascript -e 'display notification "Log bulunamadı veya boş." with title "SplitWire Loglar"'
      osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
      exit 0
    fi
    TARGET="$ERR_LOG"
    if is_empty_or_missing "$ERR_LOG"; then TARGET="$OUT_LOG"; fi
    exec bash -lc "tail -f \"$TARGET\" | /usr/bin/perl -pe 's/\e\[[0-9;]*[A-Za-z]//g'" ;;
  "Son Hatalar")
    SRC="$ERR_LOG"
    if is_empty_or_missing "$ERR_LOG"; then SRC="$OUT_LOG"; fi
    if is_empty_or_missing "$SRC"; then
      osascript -e 'display notification "Gösterilecek log bulunamadı." with title "SplitWire Loglar"'
      osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
      exit 0
    fi
    TMP_FILE="$LOG_DIR/LastErrors.txt"
    /bin/bash -lc "tail -n 200 \"$SRC\" | /usr/bin/perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' > \"$TMP_FILE\""
    open -a TextEdit "$TMP_FILE"
    osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
    exit 0 ;;
  *)
    osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'
    exit 0 ;;
esac
