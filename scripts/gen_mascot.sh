#!/usr/bin/env bash
# Generate the brand mascot frames (a cute tomato-spirit) via the Codex gpt-image
# CLI. One consistent character template + a green chroma-key background; the
# green is later removed by dealpha_pets.py. Frames feed MascotView's animation.
#
# Usage: ./scripts/gen_mascot.sh          # all frames
#        ./scripts/gen_mascot.sh wave     # one frame
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/MacFocus/Assets.xcassets/mascot"
GEN_DIR="$HOME/.codex/generated_images"

if command -v timeout >/dev/null; then TIMEOUT=(timeout 300)
elif command -v gtimeout >/dev/null; then TIMEOUT=(gtimeout 300)
else TIMEOUT=(); fi

CHAR_DESC="a cute round red tomato-spirit mascot for a focus app, glossy red tomato body, a small green leaf sprout on top, big friendly gleaming eyes, rosy cheeks, tiny stubby arms and legs, kawaii chibi flat vector mascot, bold clean outlines, simple modern style, purple-and-pink magical glow accents"
STYLE="single centered character, full body, facing viewer, flat solid pure chroma-key green background, no text, no shadow on background, cute, friendly, SFW"

POSES=(
  "idle|standing happily, gentle closed smile, arms relaxed at sides, eyes open"
  "wave|smiling and waving one little arm up in greeting, eyes open"
  "celebrate|cheering with both little arms raised up high, big happy open smile, soft glow around"
)

mkdir -p "$ASSETS"
gen_one() {
  local pose="$1" act="$2"
  local asset="mascot_${pose}"
  local prompt="$CHAR_DESC, $act, $STYLE"
  echo "▶ generating $asset ..."
  local log; log="$(mktemp)"
  if ! ${TIMEOUT[@]+"${TIMEOUT[@]}"} codex exec --skip-git-repo-check "Generate one image: $prompt" >"$log" 2>&1; then
    echo "  ✗ failed, skipping $asset"; return 1; fi
  local sid; sid="$(grep -i 'session id:' "$log" | head -1 | awk '{print $NF}')"
  [[ -z "$sid" || ! -d "$GEN_DIR/$sid" ]] && { echo "  ✗ no image dir"; return 1; }
  local png; png="$(ls -t "$GEN_DIR/$sid"/*.png 2>/dev/null | head -1 || true)"
  [[ -z "$png" ]] && { echo "  ✗ no PNG"; return 1; }
  local set_dir="$ASSETS/$asset.imageset"; mkdir -p "$set_dir"
  cp "$png" "$set_dir/$asset.png"
  cat > "$set_dir/Contents.json" <<JSON
{
  "images" : [
    { "filename" : "$asset.png", "idiom" : "universal", "scale" : "1x" },
    { "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  echo "  ✓ $asset"
}

command -v codex >/dev/null || { echo "codex CLI not found"; exit 1; }
filter="${1:-}"
for e in "${POSES[@]}"; do
  p="${e%%|*}"; a="${e#*|}"
  [[ -n "$filter" && "$p" != "$filter" ]] && continue
  gen_one "$p" "$a" || true
done
echo "Done. Next: python3 scripts/dealpha_pets.py mascot   (then build)."
