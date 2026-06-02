#!/usr/bin/env bash
# 產「同一角色的多個動作姿勢幀」給桌面夥伴做幀動畫。
# 重點:全部用同一個角色描述模板 + 綠幕背景,讓 8 張盡量一致;
# 綠幕之後由 dealpha_pets.py(角落取色 flood-fill)去背成透明。
#
# 用法:./scripts/gen_anim.sh            # 產 Celestia 全套
#       ./scripts/gen_anim.sh apple_bite # 只產指定姿勢
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/MacFocus/Assets.xcassets/pets"
GEN_DIR="$HOME/.codex/generated_images"

if command -v timeout >/dev/null; then TIMEOUT=(timeout 300)
elif command -v gtimeout >/dev/null; then TIMEOUT=(gtimeout 300)
else TIMEOUT=(); fi

# 角色 id(對應 App 內 GameCharacter.id)與固定外觀描述 —— 每張都帶,維持一致。
CHAR_ID="char_celestia"
CHAR_DESC="a cute chibi pixel-art game sprite of a celestial swordmaiden girl, big adorable head with large sparkling blue eyes, long wavy rich golden hair (deep warm gold, not pale yellow), small golden angel-wing hair ornaments, but with a noticeably full curvy bust, ornate white-and-gold plate armor with a fitted breastplate that clearly shows her chest curve, glowing golden holy sword"
STYLE="cute chibi proportions about three heads tall, big cute head and short body, but with an emphasized full chest, full body, facing the viewer, clean crisp pixel art, flat solid pure chroma-key green background, centered, fully clothed, tasteful, SFW"

# pose 名稱|該幀的動作描述
POSES=(
  "idle|standing relaxed idle pose, both hands resting at her sides, gentle closed smile, eyes open"
  "blink|standing relaxed idle pose, both hands resting at her sides, eyes closed, gentle smile"
  "sword_up|holding her glowing holy sword raised high above her head with both hands, heroic pose, eyes open"
  "sword_slash|swinging her glowing holy sword diagonally downward in a slashing motion, motion blur trail, eyes open"
  "apple_hold|happily holding up a small bright red apple in one hand, the other hand at her side, eyes open"
  "apple_bite|taking a big bite of a small bright red apple held in both hands, cheeks puffed, happy, eyes closed"
  "apple_chop|slicing a bright red apple cleanly in half with her glowing holy sword, two apple halves flying apart, eyes open"
  "walk|walking pose seen from the front, one leg stepped forward, arms swinging gently, eyes open"
)

mkdir -p "$ASSETS"
gen_one() {
  local pose="$1" act="$2"
  local asset="pet_${CHAR_ID}_${pose}"
  local prompt="$CHAR_DESC, $act, $STYLE"
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
for e in "${POSES[@]}"; do
  p="${e%%|*}"; a="${e#*|}"
  [[ -n "$filter" && "$p" != "$filter" ]] && continue
  gen_one "$p" "$a" || true
done
echo "完成。接著跑 dealpha_pets.py 去背,再 build。"
