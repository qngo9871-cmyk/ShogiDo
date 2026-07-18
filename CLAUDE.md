# Shogi Do

Native iOS app for playing Shogi (Japanese chess). Dual-market release: English
(international) + Japanese localization, both in-app UI strings and App Store metadata.

## Stack
- iOS (Swift/SwiftUI), iOS 16.0+
- XcodeGen (`project.yml`) — run `xcodegen generate` after editing project.yml
- Localization: Xcode String Catalog (`ShogiDo/Localizable.xcstrings`), en + ja
- StoreKit 2 (Products.storekit present)
- No external APIs — fully offline, native Swift AI (see Key Decisions)

## Project Structure
- `ShogiDo/Core/` — Piece, Board, MoveGenerator (pseudo-legal moves), Rules (legal-move
  filtering, drops, promotion, uchifuzume — pure/stateless, shared by GameModel + AI),
  GameModel (UI-facing game state), AIPlayer (minimax/alpha-beta), PurchaseManager
- `ShogiDo/Views/` — HomeView (difficulty picker), GameView (board + hand trays +
  promotion/game-over prompts), PieceView (kanji-on-pentagon), UpgradeView (Pro paywall)
- `rebuild.sh` — regenerate + rebuild
- `make_icon.py` — PIL-generated bold single-shape icon (pentagon piece silhouette + 将
  kanji), Hiragino Sans GB font for correct CJK glyph rendering
- `scripts/verify_rules.swift` — standalone rules-engine test harness (compiles Core/
  directly with `swiftc`, no Xcode project needed). Re-run after any Core/ change:
  `cp scripts/verify_rules.swift scripts/main.swift && swiftc -O ShogiDo/Core/*.swift scripts/main.swift -o /tmp/verify_rules && /tmp/verify_rules && rm scripts/main.swift`
- `docs/` — privacy-policy(-ja).html, support(-ja).html, served via GitHub Pages at
  https://qngo9871-cmyk.github.io/ShogiDo/
- Repo: https://github.com/qngo9871-cmyk/ShogiDo (public)

## Key Decisions (from 2026-07-18 build-gate research — see memory `project_shogi_do`)
- **Engine: did NOT use YaneuraOu/Apery/nshogi-engine — built a native Swift AI
  instead.** YaneuraOu/Apery are GPLv3 (no App Store exception exists). The build-gate
  research recommended bridging the MIT-licensed `nshogi-engine` (C++), but bridging a
  C++ MCTS engine into Swift in one session was judged too risky/slow for an end-to-end
  build — instead wrote a native Swift minimax/alpha-beta AI (`AIPlayer.swift`),
  mirroring the same approach already proven in the developer's `ChineseChess` (Xiangqi)
  app. This is both simpler AND avoids the GPL question entirely (no third-party engine
  dependency at all). Revisit nshogi-engine bridging later only if Hard difficulty needs
  to get meaningfully stronger.
- **Rules engine: built from scratch**, cross-checked against `hedjirog/SwiftShogi` and
  `codelynx/ShogibanKit` (both MIT) for edge cases, not adopted wholesale. Verified via
  `scripts/verify_rules.swift` — initial-position legal move count matches the
  known-correct value (30), knights correctly have zero legal moves at game start
  (blocked by own pawns), nifu/forced-promotion/uchifuzume all independently tested.
  **Caught a real bug this way**: the first implementation had a sign error that
  inverted every piece's forward direction for sente, silently generating illegal moves
  (initial move count was 20, not 30) — the standalone harness caught it before it ever
  reached the UI. Known gaps for v2 polish: sennichite (repetition), jishogi/impasse
  scoring (27-point rule) — not implemented, out of v1 scope.
- **Japan localization is NOT a revenue play.** The JP App Store is saturated: Shogi
  Wars (HEROZ, JSA-endorsed, ~43k ratings), Piyo Shogi (~34k), Shogi Quest (~22k) —
  ~99k combined ratings, 10+ year content/engine moats. JSA's own brand equity is
  already captured by Shogi Wars (third-party, not JSA's own app). Ship the ja
  localization for authenticity/credibility and JP-diaspora/learner audiences, not as a
  JP-market acquisition strategy. In-app UI IS fully localized (not just store
  metadata) per Q's explicit request — see Localizable.xcstrings.
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
  board/piece themes (the latter two are IAP-review-note commitments, not yet built —
  see below).

## Current State
- **2026-07-18 — v1 built end-to-end in one session: full rules engine, AI, game UI,
  StoreKit, hosting, ASC scripts. Blocked only on Apple's mandatory manual app-shell
  creation step.**

  **Built:** full shogi rules engine (legal moves for all 8 piece types + promoted
  forms, drops with nifu/uchifuzume, forced vs optional promotion, checkmate detection)
  in `Core/Rules.swift` + `MoveGenerator.swift`, verified via standalone test harness
  (`scripts/verify_rules.swift`, all 8 checks pass). Native Swift minimax AI with 3
  difficulty levels (Easy/Normal free, Hard behind Pro), capture-first move ordering,
  blunder-chance tuning per difficulty. Full SwiftUI game screen: 9x9 board, tap-to-move
  with legal-move highlighting, hand trays for both players with tap-to-drop, promotion
  confirmation dialog, checkmate alert. StoreKit 2 PurchaseManager + UpgradeView (mirrors
  Hanafuda's proven pattern exactly, product `com.quyenngo.shogido.pro`, $2.99).
  DEBUG builds force `isPro = true` (Q's own installs paywall-free, per established
  pattern). Builds clean for both simulator and device. Verified visually in simulator
  via a DEBUG-only `SHOGI_CAPTURE_GAME` launch-env hook (`ShogiDoApp.swift`) since no
  UI-automation/accessibility access was available in this session to drive real taps.

  **Hosting:** repo at `github.com/qngo9871-cmyk/ShogiDo` (public), GitHub Pages live at
  `qngo9871-cmyk.github.io/ShogiDo/` serving `docs/privacy-policy(-ja).html` +
  `docs/support(-ja).html` — both English and Japanese versions live (200 OK confirmed).

  **ASC scripts prepared (all in `~/asc-tools/`), NOT yet run** — every one of them
  requires the app to already exist in ASC, and it doesn't yet:
  - `asc_register_shogido.py` — already run successfully; bundle `com.quyenngo.shogido`
    registered (id=799R53HZ7M).
  - `asc_push_shogido.py` — categories (GAMES/GAMES_BOARD/GAMES_STRATEGY), full en-US +
    ja metadata (name/subtitle/keywords/description/promo/support+privacy URLs), the
    `.pro` non-consumable IAP with both locales' localizations. Idempotent, ready to run
    the moment the app shell exists.
  - `asc_pricing_shogido.py` — app base price Free + IAP $2.99, looks up app/IAP IDs at
    runtime (no hardcoding needed).
  - `asc_push_shogido_review.py` — age rating (all descriptors NONE/false → 4+), App
    Review Information (contact + paywall-access notes), `contentRightsDeclaration`,
    version `copyright`/`usesIdfa`.

  **🔴 BLOCKED — one manual step needed from Q:** create the app shell in App Store
  Connect UI (`POST /v1/apps` 403s for programmatic creation, as it always does — this
  is not a bug, it's Apple's policy). Once that exists, re-run the three scripts above
  in order (push → pricing → review), then proceed to archive/export/upload/screenshots/
  submit — same as every other app in this portfolio.

  **Not yet built:** tsumeshogi puzzle mode and alternate board/piece themes (both
  promised in the Pro IAP description — need building before submission, or trim the
  IAP copy if deferred to a later update), local two-player mode (not decided/scoped),
  sennichite/jishogi endgame rules (v2 polish, noted above), App Store screenshots,
  ExportOptions.plist, App Privacy nutrition labels (web-UI-only field, Q must fill).

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
say so before implementing it. When touching Core/Rules.swift or MoveGenerator.swift,
re-run scripts/verify_rules.swift before trusting the change — the sign-error bug this
session proved that visual/manual testing alone will not reliably catch a broken rules
engine.
