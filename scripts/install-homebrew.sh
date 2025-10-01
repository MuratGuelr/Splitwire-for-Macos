#!/usr/bin/env bash
set -euo pipefail

command -v brew >/dev/null && { echo "Homebrew zaten kurulu."; exit 0; }

echo "Homebrew kuruluyor…"
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
echo "Homebrew kuruldu ve PATH’e eklendi."