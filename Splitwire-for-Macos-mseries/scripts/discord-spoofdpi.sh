#!/usr/bin/env bash
set -euo pipefail

find_spoofdpi() {
  local paths=( "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi" )
  for path in "${paths[@]}"; do
    [ -x "$path" ] && { echo "$path"; return 0; }
  done
  command -v spoofdpi
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ]; then
  echo "HATA: spoofdpi çalıştırılabilir dosyası bulunamadı." >&2
  exit 1
fi

# Apple Silicon doğrulaması ve ikili mimarisi kontrolü
if [ "$(uname -m)" != "arm64" ]; then
  echo "HATA: Bu kurulum yalnızca Apple Silicon (arm64) içindir." >&2
  exit 1
fi

# spoofdpi ikilisinin arm64 olduğundan emin ol
if command -v file >/dev/null 2>&1; then
  if ! file "$SPOOF_BIN" | grep -qi "arm64"; then
    echo "HATA: spoofdpi arm64 değil. Lütfen ARM Homebrew ile yeniden kurun: 'brew uninstall spoofdpi && brew install spoofdpi'" >&2
    exit 1
  fi
fi

LISTEN_HOST="127.0.0.1"
LISTEN_PORT="${CD_PROXY_PORT:-8080}"
echo "spoofdpi başlatılıyor: $SPOOF_BIN -addr $LISTEN_HOST -port $LISTEN_PORT"
exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$LISTEN_PORT"