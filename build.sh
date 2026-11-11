#!/usr/bin/env bash
# Build custom mihomo rule-sets (mrs + classical yaml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOLS="$ROOT/.tools"
DIST="$ROOT/dist"
mkdir -p "$TOOLS" "$DIST"

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

build_mrs() {
  local behavior="$1" src="$2" dst="$3"
  echo "  $behavior  $(basename "$src")  ->  $(basename "$dst")"
  "$TOOLS/mihomo" convert-ruleset "$behavior" text "$src" "$dst"
}

for g in games discord; do
  build_mrs domain "$ROOT/rules/$g/domains.txt" "$DIST/k4reon-$g-domains.mrs"
  build_mrs ipcidr "$ROOT/rules/$g/ipcidr.txt"  "$DIST/k4reon-$g-ip.mrs"
  cp "$ROOT/rules/$g/ports.txt" "$DIST/k4reon-$g-ports.txt"
done

echo
echo "Built files:"
ls -l "$DIST"
