#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONTROL_SCRIPT_PATH="$SCRIPT_DIR/control.sh"
CURRENT_STATUS=$("$CONTROL_SCRIPT_PATH" status)

if [ "$CURRENT_STATUS" == "Aktif" ]; then
    DIALOG_TEXT="SplitWire şu anda Aktif. Discord, proxy üzerinden çalışıyor."
    BUTTON_1="Durdur"
    BUTTON_2="İptal"
else
    DIALOG_TEXT="SplitWire şu anda Pasif. Discord normal bağlantı kullanacak."
    BUTTON_1="Başlat"
    BUTTON_2="İptal"
fi

USER_CHOICE=$(osascript -e "
try
    display dialog \"$DIALOG_TEXT\" ¬
        with title \"SplitWire Kontrol Paneli\" ¬
        with icon note ¬
        buttons {\"$BUTTON_1\", \"$BUTTON_2\"} ¬
        default button \"$BUTTON_1\"
    set theChoice to button returned of the result
on error number -128
    set theChoice to \"$BUTTON_2\"
end try
return theChoice
")

if [ "$USER_CHOICE" == "Başlat" ]; then
    "$CONTROL_SCRIPT_PATH" start
    osascript -e 'display notification "SplitWire servisleri başlatıldı." with title "SplitWire"'
elif [ "$USER_CHOICE" == "Durdur" ]; then
    "$CONTROL_SCRIPT_PATH" stop
    osascript -e 'display notification "SplitWire servisleri durduruldu." with title "SplitWire"'
fi

kill $$

exit 0