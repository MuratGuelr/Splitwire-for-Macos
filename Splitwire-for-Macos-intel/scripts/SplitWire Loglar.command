#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOGS_SH="$SCRIPT_DIR/logs.sh"

USER_CHOICE=$(osascript <<'APPLESCRIPT'
try
  set optionsList to {"Hata tail -f", "Çıktı tail -f", "Son 200 Hata", "Son 200 Çıktı", "Finder'da Aç"}
  set theChoice to choose from list optionsList with title "SplitWire" with prompt "SplitWire Loglar" OK button name "Seç" cancel button name "İptal" without multiple selections allowed and empty selection allowed
  if theChoice is false then return "İptal"
  return (item 1 of theChoice)
on error number -128
  return "İptal"
end try
APPLESCRIPT
)

case "$USER_CHOICE" in
  "Hata tail -f") exec "$LOGS_SH" 1 ;;
  "Çıktı tail -f") exec "$LOGS_SH" 2 ;;
  "Son 200 Hata") "$LOGS_SH" 3; osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'; exit 0 ;;
  "Son 200 Çıktı") "$LOGS_SH" 4; osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'; exit 0 ;;
  "Finder'da Aç") "$LOGS_SH" 5; osascript -e 'tell application "Terminal" to if (count of windows) > 0 then close (first window whose frontmost is true)'; exit 0 ;;
  *) exit 0 ;;
 esac
