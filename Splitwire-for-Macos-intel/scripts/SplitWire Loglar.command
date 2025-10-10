#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOGS_SH="$SCRIPT_DIR/logs.sh"

# Basit bir GUI menü: izleme veya son satırları gösterme
USER_CHOICE=$(osascript -e '
try
  set choice to button returned of (display dialog "SplitWire Loglar" with title "SplitWire" buttons {"Hata tail -f", "Çıktı tail -f", "Son 200 Hata", "Son 200 Çıktı", "Finder'da Aç", "İptal"} default button "Finder\'da Aç")
  return choice
on error number -128
  return "İptal"
end try
')

case "$USER_CHOICE" in
  "Hata tail -f") exec "$LOGS_SH" 1 ;;
  "Çıktı tail -f") exec "$LOGS_SH" 2 ;;
  "Son 200 Hata") exec "$LOGS_SH" 3 ;;
  "Son 200 Çıktı") exec "$LOGS_SH" 4 ;;
  "Finder'da Aç") exec "$LOGS_SH" 5 ;;
  *) exit 0 ;;
 esac
