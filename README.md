# MacFocus — Focus Arcana

A gamified Pomodoro timer for macOS, built natively in SwiftUI. Turn focus
time into a collection game: complete focus sessions to earn XP, keep daily
streaks, draw new characters from a gacha, and summon an animated **desktop
companion** that cheers you on while you work.

> Display name: **Focus Arcana** · Bundle id: `com.donaldlin.macfocus` · macOS 14+

## Features

- **Pomodoro core** — 25 / 5 focus & break cycles with a large animated
  countdown ring, start / pause / skip, and a celebration when a session ends.
- **XP & levels** — every completed focus session grants XP and levels you up.
- **Daily streak** — hit your daily goal to grow a streak with a flame counter.
- **Character collection (the reward loop)** — accumulate focus hours to unlock
  characters across rarity tiers (N / R / SR / SSR). Browse them in a gallery.
- **Gacha** — spend earned points to draw new characters with a reveal animation.
- **Desktop companion** — a floating, transparent chibi pet (an `NSPanel`
  hosting SwiftUI) sits in the corner, shows your remaining focus minutes in a
  speech bubble, and reacts when you click it.
- **Stats** — daily / weekly focus charts and overall unlock progress.

## Tech stack

| Layer            | Choice                                            |
| ---------------- | ------------------------------------------------- |
| UI               | SwiftUI (macOS 14+)                               |
| Project gen      | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |
| Desktop pet      | AppKit `NSPanel` + `NSHostingView`, `TimelineView(.animation)` |
| Persistence      | `UserDefaults` (Codable) — local-first           |
| Character art    | Generated with the OpenAI **Codex CLI** image workflow (see below) |

## Build & run

This project uses **XcodeGen**, so the `.xcodeproj` is generated from
`project.yml` rather than committed.

```bash
# 1. Install XcodeGen (once)
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3a. Open in Xcode
open MacFocus.xcodeproj

# 3b. …or build from the command line (no signing required)
xcodebuild -scheme MacFocus -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

> `project.yml` contains a placeholder Apple `DEVELOPMENT_TEAM`. To run a signed
> build, change it to your own Team ID (or just use `CODE_SIGNING_ALLOWED=NO`
> for local development).

## Project layout

```
MacFocus/
  project.yml                 # XcodeGen project definition
  MacFocus/
    MacFocusApp.swift          # App entry point
    ContentView.swift          # Sidebar navigation
    Theme/                     # Colors, gradients, typography
    Components/                # CircularTimer, ConfettiView, CharacterCard, …
    Screens/                   # Timer, Collection, Gacha, Stats, Profile, Auth
    Services/                  # ProgressStore, TimerEngine, CharacterCatalog
    Models/                    # Character, FocusSession, …
    DesktopPet/                # Floating companion (PetController / PetView)
    Assets.xcassets/           # characters/ (splash art) + pets/ (chibi sprites)
  scripts/                     # AI image-generation pipeline (see below)
```

## AI-assisted character art (Codex CLI)

Character art and the chibi desktop-pet sprites are generated with the OpenAI
**Codex CLI** (`gpt-image`). The pipeline lives in `scripts/`:

- `gen_characters.sh` / `gen_pets.sh` — batch-generate splash art and chibi pets
  from a shared, consistent prompt template.
- `dealpha_pets.py` — `gpt-image` renders "transparent" backgrounds as an opaque
  fill; this script flood-fills from the corners to restore a real alpha channel.

```bash
# Requires: `npm i -g @openai/codex`, `codex login`, Python 3 + Pillow + SciPy
./scripts/gen_pets.sh            # generate all pet sprites
python3 scripts/dealpha_pets.py  # cut out the backgrounds
```

## Content note

Character art is anime / chibi splash-art style and **SFW** (fully clothed).
The reward loop is about *collecting and unlocking* characters, costumes, and
scenes — not anything explicit.

## License

[MIT](LICENSE) © 2026 Donald Lin
