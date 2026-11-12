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

export MIHOMO_BIN="$TOOLS/mihomo"

# --- 2. merge public lists + local rules ---
rm -rf "$DIST"/*
rm -f "$BUILD"/*-domains.txt "$BUILD"/*-ip.txt "$BUILD"/upstream-*
echo "Merging sources..."
python3 "$ROOT/scripts/merge.py"

# --- 3. build mrs ---
build_mrs() {
  local behavior="$1" src="$2" dst="$3"
  echo "  $behavior  $(basename "$src")  ->  $(basename "$dst")"
  "$TOOLS/mihomo" convert-ruleset "$behavior" text "$src" "$dst"
}

for f in "$BUILD"/*-domains.txt; do
  [ -e "$f" ] || continue
  g="$(basename "$f" -domains.txt)"
  build_mrs domain "$f" "$DIST/k4reon-$g-domains.mrs"
done
for f in "$BUILD"/*-ip.txt; do
  [ -e "$f" ] || continue
  g="$(basename "$f" -ip.txt)"
  build_mrs ipcidr "$f" "$DIST/k4reon-$g-ip.mrs"
done

# --- 4. copy classical rule files ---
find "$ROOT/rules" -mindepth 2 -maxdepth 2 -type f -name '*.txt' \
  ! -name 'domains.txt' ! -name 'ipcidr.txt' | while read -r f; do
    g="$(basename "$(dirname "$f")")"
    cp "$f" "$DIST/k4reon-$g-$(basename "$f")"
  done

# --- 5. publish readable full lists (merged, not just local additions) ---
rm -rf "$DIST/lists"
mkdir -p "$DIST/lists"
for f in "$BUILD"/*-domains.txt; do
  [ -e "$f" ] || continue
  g="$(basename "$f" -domains.txt)"
  cp "$f" "$DIST/lists/k4reon-$g-domains.txt"
done
for f in "$BUILD"/*-ip.txt; do
  [ -e "$f" ] || continue
  g="$(basename "$f" -ip.txt)"
  cp "$f" "$DIST/lists/k4reon-$g-ip.txt"
done

echo
echo "Built files:"
ls -l "$DIST"
