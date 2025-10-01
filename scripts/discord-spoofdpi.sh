#!/usr/bin/env bash
# Hata durumunda hemen çık
set -euo pipefail

# Bu betik doğrudan launchd tarafından yönetildiği için loglama,
# launchd plist dosyasındaki StandardOutPath ve StandardErrorPath üzerinden yapılır.

# spoofdpi'ın nerede olduğunu bulmaya çalış
find_spoofdpi() {
  # Homebrew'un Apple Silicon ve Intel Mac'lerdeki varsayılan yolları
  local paths=(
    "/opt/homebrew/bin/spoofdpi"
    "/usr/local/bin/spoofdpi"
  )
  for path in "${paths[@]}"; do
    if [ -x "$path" ]; then
      echo "$path"
      return 0
    fi
  done
  # Eğer yollarda bulunamazsa, PATH içinde ara
  if command -v spoofdpi >/dev/null 2>&1; then
    command -v spoofdpi
    return 0
  fi
  return 1
}

SPOOF_BIN=$(find_spoofdpi)

if [ -z "${SPOOF_BIN}" ]; then
  # Bu hata, launchd tarafından belirtilen .err.log dosyasına yazılacak
  echo "HATA: spoofdpi çalıştırılabilir dosyası bulunamadı." >&2
  echo "Lütfen 'brew install spoofdpi' komutu ile kurun." >&2
  exit 1
fi

LISTEN_HOST="127.0.0.1"
# Ortam değişkeni ayarlı değilse varsayılan olarak 8080 portunu kullan
LISTEN_PORT="${CD_PROXY_PORT:-8080}"

echo "spoofdpi başlatılıyor: $SPOOF_BIN -addr $LISTEN_HOST -port $LISTEN_PORT"

# `exec` komutu, bu betik sürecini sonlandırır ve yerine spoofdpi sürecini başlatır.
# Bu, launchd'nin `KeepAlive` ile doğrudan spoofdpi'ı yönetmesini sağlar.
exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$LISTEN_PORT"