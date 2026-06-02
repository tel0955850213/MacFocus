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
STYLE="anime / League-of-Legends splash-art style, glamorous confident adult woman, fully clothed in elegant fantasy outfit, dramatic lighting, vertical portrait, clean background, high detail, SFW"

# assetName|英文立繪描述(≤350 字,結尾自動加風格)
CHARACTERS=(
  "char_aurora|A dawn-ranger heroine with golden hair, light leather armor and a glowing bow, warm sunrise tones"
  "char_vela|A night-wind assassin with short silver hair, sleek dark hooded outfit, cool blue moonlight tones"
  "char_lyra|A starlit bard with flowing teal hair, ornate blue gown and a luminous harp, cosmic sparkles"
  "char_seraphine|A tide sorceress with long aqua hair, flowing ocean-blue robes, water swirling around her"
  "char_ember|A flame mage with fiery red hair, ornate purple-and-gold battle dress, embers and sparks around her"
  "char_noctis|A shadow queen with long black hair, elegant dark violet royal gown, swirling shadow magic"
  "char_celestia|A celestial swordmaiden in radiant white-and-orange armor, golden halo, holy sword, heavenly glow"
  "char_aphrodite|A dawn goddess with rose-gold hair, flowing pink-and-gold divine dress, soft luminous aura"
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
