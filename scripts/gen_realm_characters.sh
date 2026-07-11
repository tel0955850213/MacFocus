#!/usr/bin/env bash
# Generate the first three-realm roster with the Codex gpt-image-2 pipeline.
# Each entry is one clean full-body character image; no sprite sheets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/MacFocus/Assets.xcassets/characters"
GEN_DIR="$HOME/.codex/generated_images"

if command -v timeout >/dev/null; then TIMEOUT=(timeout 300)
elif command -v gtimeout >/dev/null; then TIMEOUT=(gtimeout 300)
else TIMEOUT=(); fi

STYLE="original fantasy game character splash art, full body, face clearly visible, vertical portrait, dramatic but elegant lighting, polished anime illustration, rich mythic worldbuilding, no text, SFW, distinct facial identity, no generic repeated anime face, do not resemble any other roster character"
SMALLFOLK="original short non-human smallfolk adult character, compact heroic proportions, large expressive eyes, rounded ears, magical facial markings, whimsical but powerful, not an animal, not an elf, not a robot, not a child"

CHARACTERS=(
  "char_elyra|an adult woman dawn oracle of Asterra, white-and-gold temple attire, sun-crown jewelry, a crystal prayer lantern, calm determined gaze"
  "char_caelith|an adult man oathwarden of Asterra, radiant blue-and-gold plate armor, ceremonial spear, star-shaped heraldry, noble protective stance"
  "char_miri|$SMALLFOLK, a starseed scout from Asterra, tiny white cloak, gold compass charm, soft green and amber palette"
  "char_vespera|an adult woman dream cantor of Elyrion, deep violet layered robes, silver throat jewelry, floating lyric ribbons, luminous moonlit eyes"
  "char_orlan|an adult man veil scribe of Elyrion, midnight scholar coat, ink-blue scroll case, constellation tattoos, quiet prophetic expression"
  "char_pellin|$SMALLFOLK, a masked seer from Elyrion, lavender hood, hand-painted porcelain mask held beside the face, tiny dream lantern, mysterious smile"
  "char_kaedra|an adult woman red oathblade of Kharvane, crimson fitted battle coat with full coverage, black braided hair, greatsword, fierce confident gaze"
  "char_theron|an adult man ash warlord of Kharvane, charcoal armor with red oath cloth, scarred ceremonial pauldrons, heavy two-handed blade, commanding stance"
  "char_brindle|$SMALLFOLK, a sparkpot runner from Kharvane, compact adventurer, rust-red scarf, enchanted clay firework pot, mischievous grin, smoky orange light"
)

gen_one() {
  local asset="$1" desc="$2"
  local prompt="$desc, $STYLE"
  echo "Generating $asset with gpt-image-2..."
  local log
  log="$(mktemp)"
  if ! ${TIMEOUT[@]+"${TIMEOUT[@]}"} codex exec --model gpt-image-2 --skip-git-repo-check \
      "Generate one image: $prompt" >"$log" 2>&1; then
    echo "Generation failed for $asset"
    cat "$log"
    return 1
  fi

  local sid
  sid="$(grep -i 'session id:' "$log" | head -1 | awk '{print $NF}')"
  if [[ -z "$sid" || ! -d "$GEN_DIR/$sid" ]]; then
    echo "No Codex image directory found for $asset"
    return 1
  fi

  local png
  png="$(ls -t "$GEN_DIR/$sid"/*.png 2>/dev/null | head -1 || true)"
  if [[ -z "$png" ]]; then
    echo "No PNG found for $asset"
    return 1
  fi

  local set_dir="$ASSETS/$asset.imageset"
  mkdir -p "$set_dir"
  cp "$png" "$set_dir/$asset.png"
  printf '%s\n' '{' \
    '  "images" : [' \
    "    { \"filename\" : \"$asset.png\", \"idiom\" : \"universal\", \"scale\" : \"1x\" }," \
    '    { "idiom" : "universal", "scale" : "2x" },' \
    '    { "idiom" : "universal", "scale" : "3x" }' \
    '  ],' \
    '  "info" : { "author" : "xcode", "version" : 1 }' \
    '}' > "$set_dir/Contents.json"
  echo "Saved $asset"
}

main() {
  command -v codex >/dev/null || { echo "codex CLI is required"; exit 1; }
  local filter="${1:-}"
  for entry in "${CHARACTERS[@]}"; do
    local asset="${entry%%|*}" desc="${entry#*|}"
    [[ -n "$filter" && "$asset" != "$filter" ]] && continue
    gen_one "$asset" "$desc" || true
  done
}

main "$@"
