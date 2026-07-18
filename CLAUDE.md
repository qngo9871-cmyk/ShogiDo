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
- **2026-07-19 — fully built and submitted-except-one-tick.** App shell created by Q in
  ASC UI (id=6792362960), everything else pushed via API.

  **Built:** full shogi rules engine (legal moves for all 8 piece types + promoted
  forms, drops with nifu/uchifuzume, forced vs optional promotion, checkmate detection)
  in `Core/Rules.swift` + `MoveGenerator.swift`, verified via standalone test harness
  (`scripts/verify_rules.swift`, all 8 checks pass — this caught a real sign-error bug).
  Native Swift minimax AI with 3 difficulty levels (Easy/Normal free, Hard behind Pro).
  Full SwiftUI game screen: 9x9 board, tap-to-move with legal-move highlighting, hand
  trays with tap-to-drop, promotion confirmation dialog, checkmate alert. StoreKit 2
  PurchaseManager + UpgradeView, product `com.quyenngo.shogido.pro` ($2.99, Hard AI
  only — tsumeshogi/themes trimmed from the IAP copy since they weren't built, see
  below). **First-launch onboarding + always-accessible `HowToPlayView`** (EN+JA,
  `@AppStorage("hasSeenOnboarding")`, toolbar icon on Home) — added after Q's standing
  rule [[feedback_app_onboarding_instructions]] that every app needs this. Local
  `Products.storekit` wired into the scheme's Run action (`storeKitConfiguration` in
  project.yml) so real IAP pricing renders in the simulator without a sandbox tester.

  **Hosting:** `github.com/qngo9871-cmyk/ShogiDo` (public), GitHub Pages live at
  `qngo9871-cmyk.github.io/ShogiDo/` serving EN+JA privacy/support pages.

  **ASC — all pushed via API:** app metadata (categories GAMES/GAMES_BOARD/
  GAMES_STRATEGY, en-US+ja name/subtitle/keywords/description/promo/URLs via
  `asc_push_shogido.py`), pricing (app free, IAP $2.99 via `asc_pricing_shogido.py`),
  age rating (4+) + review contact/notes + copyright/contentRights (via
  `asc_push_shogido_review.py`), 5 App Store screenshots per locale (home/board/
  select/hand/check, via `capture_shots.py` + `asc_push_shogido_screenshots.py`), the
  IAP's own private review screenshot (paywall, via
  `asc_upload_shogido_iap_screenshot.py`). Build 2 (bumped from 1 after adding
  onboarding) archived/exported/uploaded/attached to version 1.0.0 — exporting a
  brand-new bundle's first distribution profile needed **both**
  `-authenticationKeyPath/-ID/-IssuerID` **and** `-allowProvisioningUpdates` together
  (the auth-key flags alone weren't enough this time, unlike the archived pattern in
  `~/.claude/CLAUDE.md` which only mentions the auth-key flags).

  **🟢 SUBMITTED 2026-07-19.** Q ticked the Pro IAP into version 1.0.0's own page,
  filled App Privacy nutrition labels, un-ticked Vision Pro + iPhone-on-Mac. That left
  a `reviewSubmissions` draft (`READY_FOR_REVIEW`, `submittedDate: null`) whose only
  attached item was the IAP — **the version itself was never actually attached**, so
  `PATCH .../reviewSubmissions/{id} {submitted:true}` 409'd
  (`RELATIONSHIP.REQUIRED` / `appStoreVersionForReview`). Fixed by `POST
  reviewSubmissionItems` with an explicit `appStoreVersion` relationship pointing at
  the version, THEN the submit PATCH succeeded: `state: WAITING_FOR_REVIEW`,
  `submittedDate` set. releaseType is `AFTER_APPROVAL` — no further action needed once
  Apple approves it.

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
