#!/usr/bin/env bash
set -euo pipefail

# Mac mimarisini tespit et
ARCH=$(uname -m)
echo "Mac mimarisi tespit edildi: $ARCH"

# Homebrew kurulum yolunu tespit et
detect_homebrew_path() {
  if [ -x "/opt/homebrew/bin/brew" ]; then
    echo "/opt/homebrew"
  elif [ -x "/usr/local/bin/brew" ]; then
    echo "/usr/local"
  else
    echo ""
  fi
}

HOMEBREW_PREFIX=$(detect_homebrew_path)
if [ -z "$HOMEBREW_PREFIX" ]; then
  echo "HATA: Homebrew bulunamadı. Lütfen önce Homebrew kurun." >&2
  exit 1
fi

echo "Homebrew prefix: $HOMEBREW_PREFIX"

# spoofdpi binary'sini bul
find_spoofdpi() {
  local paths=(
    "$HOMEBREW_PREFIX/bin/spoofdpi"
    "/opt/homebrew/bin/spoofdpi"
    "/usr/local/bin/spoofdpi"
    "/usr/bin/spoofdpi"
  )
  
  for path in "${paths[@]}"; do
    if [ -x "$path" ]; then
      echo "spoofdpi bulundu: $path"
      echo "$path"
      return 0
    fi
  done
  
  # PATH'te ara
  if command -v spoofdpi >/dev/null 2>&1; then
    local cmd_path=$(command -v spoofdpi)
    echo "spoofdpi PATH'te bulundu: $cmd_path"
    echo "$cmd_path"
    return 0
  fi
  
  return 1
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ]; then
  echo "HATA: spoofdpi çalıştırılabilir dosyası bulunamadı." >&2
  echo "Kontrol edilen yollar:" >&2
  echo "  - $HOMEBREW_PREFIX/bin/spoofdpi" >&2
  echo "  - /opt/homebrew/bin/spoofdpi" >&2
  echo "  - /usr/local/bin/spoofdpi" >&2
  echo "  - /usr/bin/spoofdpi" >&2
  echo "  - PATH içinde" >&2
  echo "" >&2
  echo "Çözüm önerileri:" >&2
  echo "  1. Homebrew ile spoofdpi kurun: brew install spoofdpi" >&2
  echo "  2. PATH'inizi kontrol edin: echo \$PATH" >&2
  echo "  3. Homebrew'u yeniden kurun: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" >&2
  exit 1
fi

# Binary'nin çalışabilir olduğunu test et
if ! "$SPOOF_BIN" -h >/dev/null 2>&1; then
  echo "HATA: spoofdpi binary'si çalıştırılamıyor: $SPOOF_BIN" >&2
  echo "Binary dosyasını kontrol edin veya yeniden kurun." >&2
  exit 1
fi

LISTEN_HOST="127.0.0.1"
LISTEN_PORT="${CD_PROXY_PORT:-8080}"

echo "spoofdpi başlatılıyor:"
echo "  Binary: $SPOOF_BIN"
echo "  Host: $LISTEN_HOST"
echo "  Port: $LISTEN_PORT"
echo "  Mimari: $ARCH"

exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$LISTEN_PORT"