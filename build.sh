#!/usr/bin/env bash
# Build k4reon mihomo rule-sets: merge public sources + local additions.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOLS="$ROOT/.tools"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
mkdir -p "$TOOLS" "$BUILD" "$DIST"

# --- 1. mihomo ---
if [ ! -x "$TOOLS/mihomo" ]; then
  echo "Downloading latest mihomo for $(uname -s)/$(uname -m)..."
  URL="$(curl -fsSL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
    | grep browser_download_url \
    | grep 'linux-amd64' \
    | grep -v 'compatible' \
    | head -n1 \
    | cut -d '"' -f4)"
  [ -n "$URL" ] || { echo "mihomo asset not found" >&2; exit 1; }

  case "$URL" in
    *.gz)
      curl -fL "$URL" -o "$TOOLS/mihomo.gz"
      gunzip -f "$TOOLS/mihomo.gz"
      mv "$TOOLS/mihomo" "$TOOLS/mihomo.bin"
      ;;
    *.zip)
      curl -fL "$URL" -o "$TOOLS/mihomo.zip"
      unzip -o "$TOOLS/mihomo.zip" -d "$TOOLS" >/dev/null
      rm -f "$TOOLS/mihomo.zip"
      ;;
    *)
      echo "Unsupported archive: $URL" >&2; exit 1 ;;
  esac

  if [ -f "$TOOLS/mihomo.bin" ]; then
    mv "$TOOLS/mihomo.bin" "$TOOLS/mihomo"
  elif [ ! -f "$TOOLS/mihomo" ]; then
    FOUND="$(find "$TOOLS" -maxdepth 2 -type f -name 'mihomo*' ! -name '*.gz' ! -name '*.zip' | head -n1)"
    [ -n "$FOUND" ] || { echo "mihomo binary not found" >&2; exit 1; }
    mv "$FOUND" "$TOOLS/mihomo"
  fi
  chmod +x "$TOOLS/mihomo"
fi

# --- 2. upstream game IP list (Keviin Game_IP.mrs -> text) ---
GAME_IP_URL="https://raw.githubusercontent.com/Keviin560/Shunt_Rules/main/rule/Mihomo/Game_IP.mrs"
echo "Downloading upstream Game_IP.mrs..."
curl -fL "$GAME_IP_URL" -o "$BUILD/upstream-game-ip.mrs"
"$TOOLS/mihomo" convert-ruleset ipcidr mrs "$BUILD/upstream-game-ip.mrs" "$BUILD/upstream-game-ip.txt"

# --- 3. merge public lists + local rules ---
echo "Merging sources..."
python3 "$ROOT/scripts/merge.py"

# --- 4. build mrs ---
build_mrs() {
  local behavior="$1" src="$2" dst="$3"
  echo "  $behavior  $(basename "$src")  ->  $(basename "$dst")"
  "$TOOLS/mihomo" convert-ruleset "$behavior" text "$src" "$dst"
}

build_mrs domain "$BUILD/games-domains.txt"   "$DIST/k4reon-games-domains.mrs"
build_mrs ipcidr "$BUILD/games-ip.txt"        "$DIST/k4reon-games-ip.mrs"
build_mrs domain "$BUILD/discord-domains.txt" "$DIST/k4reon-discord-domains.mrs"
build_mrs ipcidr "$BUILD/discord-ip.txt"      "$DIST/k4reon-discord-ip.mrs"
build_mrs domain "$BUILD/ru-domains.txt"      "$DIST/k4reon-ru-domains.mrs"

cp "$ROOT/rules/games/ports.txt"    "$DIST/k4reon-games-ports.txt"
cp "$ROOT/rules/discord/ports.txt"  "$DIST/k4reon-discord-ports.txt"
cp "$ROOT/rules/ru/classical.txt"   "$DIST/k4reon-ru-classical.txt"

echo
echo "Built files:"
ls -l "$DIST"
