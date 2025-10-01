#!/usr/bin/env bash
# BitBar / SwiftBar plugin
# Menü-bar: SplitWire  |  Başlat / Durdur / Log Gör

STAT=$(launchctl list | grep net.consolaktif.discord.spoofdpi || echo "-")
if [[ "$STAT" == "-" ]]; then
  echo "🔴  SW"
  echo "---"
  echo "Başlat | bash='$0' param1=start terminal=false"
else
  echo "🟢  SW"
  echo "---"
  echo "Durdur | bash='$0' param1=stop terminal=false"
fi
echo "---"
echo "Log Gör | bash='$0' param1=log terminal=true"
echo "Yenile | refresh=true"

case "$1" in
  start)
    launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist
    launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist
    osascript -e 'display notification "SplitWire başlatıldı" with title "SW"'
    ;;
  stop)
    launchctl unload -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist 2>/dev/null
    launchctl unload -w ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist 2>/dev/null
    osascript -e 'display notification "SplitWire durduruldu" with title "SW"'
    ;;
  log)
    open -a Console ~/Library/Logs/net.consolaktif.discord.spoofdpi.err.log
    ;;
esac