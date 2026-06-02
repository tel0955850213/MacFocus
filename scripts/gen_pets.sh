#!/usr/bin/env bash
# 產角色的「像素 chibi」桌面夥伴 sprite(透明背景),接進 Assets.xcassets/pets。
# 透明 PNG → Codex 會自動 fallback 到 gpt-image-1.5。
# 用法:./scripts/gen_pets.sh  或  ./scripts/gen_pets.sh pet_ember
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/MacFocus/Assets.xcassets/pets"
GEN_DIR="$HOME/.codex/generated_images"
STYLE="cute chibi pixel-art game sprite, full body, big head, facing the viewer, standing idle pose, clean crisp pixels, transparent background, centered, SFW"

if command -v timeout >/dev/null; then TIMEOUT=(timeout 300)
elif command -v gtimeout >/dev/null; then TIMEOUT=(gtimeout 300)
else TIMEOUT=(); fi

PETS=(
  "pet_char_aurora|a dawn-ranger girl with golden hair, light armor and a small bow, warm tones"
  "pet_char_vela|a night assassin girl with short silver hair, dark hooded outfit, blue tones"
  "pet_char_lyra|a starlit bard girl with teal hair, blue gown holding a tiny harp"
  "pet_char_seraphine|a tide sorceress girl with aqua hair, ocean-blue robes"
  "pet_char_ember|a fire mage girl with red hair, purple-and-gold dress, tiny flames"
  "pet_char_noctis|a shadow queen girl with long black hair, dark violet gown"
  "pet_char_celestia|a celestial swordmaiden girl in white-and-gold armor with a tiny sword"
  "pet_char_aphrodite|a dawn goddess girl with rose-gold hair, pink-and-gold dress"
)

mkdir -p "$ASSETS"
gen_one() {
  local asset="$1" desc="$2"
  local prompt="$desc, $STYLE"
  echo "▶ 生成 $asset ..."
  local log; log="$(mktemp)"
  if ! ${TIMEOUT[@]+"${TIMEOUT[@]}"} codex exec --skip-git-repo-check "Generate one image: $prompt" >"$log" 2>&1; then
    echo "  ✗ 失敗,略過 $asset"; return 1; fi
  local sid; sid="$(grep -i 'session id:' "$log" | head -1 | awk '{print $NF}')"
  [[ -z "$sid" || ! -d "$GEN_DIR/$sid" ]] && { echo "  ✗ 無影像目錄"; return 1; }
  local png; png="$(ls -t "$GEN_DIR/$sid"/*.png 2>/dev/null | head -1 || true)"
  [[ -z "$png" ]] && { echo "  ✗ 無 PNG"; return 1; }
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
command -v codex >/dev/null || { echo "找不到 codex CLI"; exit 1; }
filter="${1:-}"
for e in "${PETS[@]}"; do
  a="${e%%|*}"; d="${e#*|}"
  [[ -n "$filter" && "$a" != "$filter" ]] && continue
  gen_one "$a" "$d" || true
done
echo "完成。"
