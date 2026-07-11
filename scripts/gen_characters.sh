#!/usr/bin/env bash
# 用 Codex CLI(gpt-image-2)批量產生角色立繪,並接進 Assets.xcassets/characters。
#
# 前置:
#   1. 安裝 Codex CLI:npm install -g @openai/codex
#   2. codex login(需要 ChatGPT Plus,影像生成免費帳號不可用)
#
# 用法:
#   ./scripts/gen_characters.sh            # 產全部角色
#   ./scripts/gen_characters.sh char_ember # 只產指定角色
#
# 內容界線:只產「穿著時髦、華麗、撩人的成年女角色」立繪(SFW),
# 不產裸露/露骨內容 —— OpenAI 影像模型本身也會擋。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/MacFocus/Assets.xcassets/characters"
GEN_DIR="$HOME/.codex/generated_images"

# macOS 沒有內建 timeout;有 gtimeout(brew coreutils)就用,否則不包 timeout。
if command -v timeout >/dev/null; then TIMEOUT=(timeout 300)
elif command -v gtimeout >/dev/null; then TIMEOUT=(gtimeout 300)
else TIMEOUT=(); fi
STYLE="original mythic fantasy game character splash art, fully clothed adult character, dramatic lighting, vertical portrait, clean readable silhouette, high detail, SFW, distinct facial identity, no generic repeated anime face, do not resemble any other roster character"

# assetName|英文立繪描述(≤350 字,結尾自動加風格)
CHARACTERS=(
  "char_aurora|Aurora, an adult dawn ranger with sun-kissed warm brown skin, bright green almond eyes, a rounder friendly face with visible freckles, braided golden-brown hair, practical light leather armor, a glowing bow, and a small hawk-shaped dawn spirit"
  "char_vela|Vela, an adult night assassin with deep umber skin, sharp hooded eyes, a narrow angular face, short silver hair with one long braid, a sleek fully covered dark outfit, twin crescent blades, and a silent blue moth spirit"
  "char_lyra|Lyra, an adult starlit bard with deep brown skin, wide luminous violet eyes, a soft square face, flowing teal curls, an ornate blue gown, a luminous harp, and a constellation whale spirit made of stars"
  "char_seraphine|Seraphine, an adult tide sorceress with cool olive skin, turquoise eyes, a long elegant face, waist-length aqua hair swept to one side, flowing ocean-blue robes, water ribbons, and a translucent koi spirit"
  "char_ember|Ember, an adult flame mage with copper skin, golden-brown eyes, a strong high-cheekboned face, short fiery red curls, a fully covered purple-and-gold battle dress, ember sigils, and a tiny phoenix spirit"
  "char_noctis|Noctis, an adult shadow queen with blue-black skin, pale silver eyes, a severe diamond-shaped face, long straight black hair, an elegant dark violet royal gown, shadow veils, and a quiet raven spirit"
  "char_celestia|Celestia, an adult celestial swordmaiden with porcelain skin, deep sapphire eyes, a solemn angular heart-shaped face, long rich golden hair, radiant white-and-orange full armor, geometric star halo, holy sword, and a small orbiting sun spirit"
  "char_aphrodite|Aphrodite, an adult dawn goddess with warm olive skin, luminous violet eyes, broad cheekbones, a confident full-lipped smile, rose-pink hair with loose waves, a fully clothed pink-and-gold divine outfit, rose constellations, and a floating heart-flame spirit"
)

gen_one() {
  local asset="$1" desc="$2"
  local prompt="$desc, $STYLE"
  echo "▶ 生成 $asset ..."
  local log; log="$(mktemp)"
  if ! ${TIMEOUT[@]+"${TIMEOUT[@]}"} codex exec --skip-git-repo-check "Generate one image: $prompt" >"$log" 2>&1; then
    echo "  ✗ codex exec 失敗(timeout 或錯誤),略過 $asset"; cat "$log"; return 1
  fi
  local sid; sid="$(grep -i 'session id:' "$log" | head -1 | awk '{print $NF}')"
  if [[ -z "$sid" || ! -d "$GEN_DIR/$sid" ]]; then
    echo "  ✗ 找不到 session 影像目錄,略過 $asset"; return 1
  fi
  local png; png="$(ls -t "$GEN_DIR/$sid"/*.png 2>/dev/null | head -1 || true)"
  if [[ -z "$png" ]]; then echo "  ✗ 該 session 沒有 PNG,略過 $asset"; return 1; fi

  local set_dir="$ASSETS/$asset.imageset"
  mkdir -p "$set_dir"
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
  echo "  ✓ $asset 已寫入 $set_dir"
}

main() {
  command -v codex >/dev/null || { echo "找不到 codex CLI,先 npm install -g @openai/codex"; exit 1; }
  local filter="${1:-}"
  for entry in "${CHARACTERS[@]}"; do
    local asset="${entry%%|*}" desc="${entry#*|}"
    [[ -n "$filter" && "$asset" != "$filter" ]] && continue
    gen_one "$asset" "$desc" || true
  done
  echo "完成。重新 xcodegen generate 後 build,立繪即會出現在 App。"
}

main "$@"
