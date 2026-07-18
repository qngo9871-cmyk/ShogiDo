# Shogi Do

Native iOS app for playing Shogi (Japanese chess). Dual-market release: English
(international) + Japanese localization, both in-app UI strings and App Store metadata.

## Stack
- iOS (Swift/SwiftUI), iOS 16.0+
- XcodeGen (`project.yml`) — run `xcodegen generate` after editing project.yml
- Localization: Xcode String Catalog (`ShogiDo/Localizable.xcstrings`), en + ja
- No external APIs planned yet (engine choice below is offline/on-device)

## Project Structure
- `ShogiDo/Core/` — Board.swift (piece/board data model only so far — no rules engine yet)
- `ShogiDo/Views/` — HomeView (placeholder)
- `rebuild.sh` — regenerate + rebuild
- `make_icon.py` — PIL-generated bold single-shape icon (pentagon piece silhouette + 将
  kanji), Hiragino Sans GB font for correct CJK glyph rendering

## Key Decisions (from 2026-07-18 build-gate research — see memory `project_shogi_do`)
- **Engine: do NOT use YaneuraOu or Apery.** Both are GPLv3. There is no App Store
  exception — GPL requires the whole binary to be open-sourced if linked in, and
  existing iOS chess apps using GPL engines are non-compliant, not a safe precedent.
  Use **`nshogi-engine`** (MIT-licensed, C++, MCTS/AlphaZero-style) via a C++→Swift
  bridge instead. Weaker tournament strength than YaneuraOu but legally clean, and
  plenty for a casual app.
- **Rules engine: build it ourselves**, no ready-to-fork Swift implementation exists.
  Reference (don't wholesale-adopt) `hedjirog/SwiftShogi` (MIT, bitboard rules, stale
  since 2020) and `codelynx/ShogibanKit` (MIT, has drop/promotion, TODO on uchifuzume)
  for edge-case cross-checking. Board rendering/turn-handling/persistence can mostly
  carry over conceptually from `ChineseChess` (same developer's Xiangqi app). The one
  real algorithmic wrinkle is **uchifuzume** (pawn-drop-checkmate is illegal) — requires
  full checkmate detection at drop-generation time, not just extra piece-movement rules.
  Rough estimate: 1–2 weeks total for a working rules engine + drop/promotion UI.
- **Japan localization is NOT a revenue play.** The JP App Store is saturated: Shogi
  Wars (HEROZ, JSA-endorsed, ~43k ratings), Piyo Shogi (~34k), Shogi Quest (~22k) —
  ~99k combined ratings, 10+ year content/engine moats. JSA's own brand equity is
  already captured by Shogi Wars (third-party, not JSA's own app). Ship the ja
  localization for authenticity/credibility and JP-diaspora/learner audiences, not as a
  JP-market acquisition strategy.
- **English/international market is the real opportunity.** Best existing English-market
  app ("Shogi") caps at ~522 ratings — genuinely thin shelf. Demand is flat-to-stable
  globally though, not growing: no Chess.com/Lichess crossover, small/flat English
  community (81dojo, Lishogi). Fujii Sota's historic 8-title run is a real marketing
  hook but is **Japan-only** — doesn't move English-market discovery, don't lean on it
  for US/global ASO.
- **Naming: "Shogi Do"** (道, "the way") — reads naturally in both languages, no
  collision on either storefront. Backup: "Shogi Pro Dojo". Avoid "Shogi Pro
  Classic"/"Shogi Master" variants — too close to existing "Classic Shogi Game/Master"
  entries. Keep "Shogi" in romaji for English ASO; use 将棋/将棋アプリ/本将棋 in the
  Japanese keyword field (JP ranking is kanji-keyword-driven, not brand-name-driven).
- **Bundle ID:** `com.quyenngo.shogido`
- **Monetization: Free + $2.99 Pro one-time unlock**, matching Hanafuda Koi-Koi's live,
  proven pattern exactly. Free tier: Easy/Normal AI, standard play. Pro
  (`com.quyenngo.shogido.pro`, non-consumable): Hard AI, tsumeshogi puzzle mode, alt
  board/piece themes.

## Current State
- **2026-07-18 — scaffolded only.** project.yml (XcodeGen), Info.plist (auto-generated),
  Localizable.xcstrings with a handful of en/ja placeholder strings, minimal SwiftUI
  skeleton (App entry + HomeView placeholder), Core/Board.swift (piece/board data model
  stub, no rules/legality logic yet), placeholder icon. Builds clean for simulator
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build` exits 0).
- Bundle ID `com.quyenngo.shogido` registered via API (`~/asc-tools/asc_register_shogido.py`,
  id=799R53HZ7M). App listing creation 403'd as always (Apple blocks `POST /v1/apps`) —
  Q needs to create the app shell manually in ASC UI when ready to move toward submission.
- git repo initialized locally, not yet pushed (no GitHub remote created).
- **Not yet done:** rules engine (legal move generation, drop/promotion, uchifuzume,
  check/checkmate detection), AI opponent (nshogi-engine bridge), game UI (board
  rendering, hand tray, promotion prompt), StoreKit 2 + PurchaseManager for the Pro IAP,
  screenshots, ASC app listing (manual, see above), privacy policy/support pages.

## Instructions for Claude Code
At the end of every session, update the Current State section to reflect progress made.

## Reasoning Mode
You are a shogi player who understands the game's real strategic character — not
Western chess with different pieces. Piece drops and promotion aren't cosmetic rule
differences; they're what make shogi shogi, and getting uchifuzume, nifu (two pawns on
one file), and promotion-zone edge cases wrong will be immediately obvious to anyone who
actually plays. As an iOS developer you care about a clean hand-tray/drop UX and correct
CJK rendering (verify glyphs visually, don't trust "the script ran without error" — see
the Hanafuda font-fallback bug in `~/.claude/CLAUDE.md`). If a requested shortcut would
produce an illegal-rules engine or a shallow reskin instead of a real shogi experience,
say so before implementing it.
