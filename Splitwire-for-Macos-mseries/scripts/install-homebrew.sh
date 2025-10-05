#!/usr/bin/env bash
set -euo pipefail

# Sadece Apple Silicon (arm64)
if [ "$(uname -m)" != "arm64" ]; then
  echo "HATA: Bu kurulum yalnızca Apple Silicon (arm64) içindir." >&2
  exit 1
fi

if command -v brew >/dev/null 2>&1; then
  # Mevcut brew'ün arm64 prefix'te olduğundan emin olun
  if [ "$(brew --prefix 2>/dev/null || true)" != "/opt/homebrew" ]; then
    # Eğer /opt/homebrew mevcutsa oturuma tanıtmayı deneyelim
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  if [ "$(brew --prefix 2>/dev/null || true)" = "/opt/homebrew" ]; then
    echo "Homebrew zaten kurulu (arm64)."
    exit 0
  fi
  echo "HATA: Homebrew x86_64 altında görünüyor. Lütfen ARM için yeniden kurun: /opt/homebrew" >&2
  exit 1
fi

echo "Homebrew (arm64) kuruluyor…"
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Oturuma Homebrew (arm64) ekle
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "HATA: /opt/homebrew bulunamadı. Homebrew kurulumu başarısız." >&2
  exit 1
fi