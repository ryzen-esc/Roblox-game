# PROJECT STATE — Fish Tank Simulator

**Last updated:** 2026-09-07 (session 2 — post-playtest fixes + full re-review). Read this file first if resuming this project with no other context — it's written to be self-sufficient.

## What this is

A Roblox game business project: research a market opportunity, design, build, and prepare for launch a solo-developer-maintainable Roblox experience with a realistic path to ~$100/month, per the full brief in the original task (see git history / conversation for the verbatim brief if needed — the important decisions from it are captured below).

## Chosen concept

**"Fish Tank Simulator"** — cast a line to catch fish (short, skill-based active minigame) → fish live and grow in the player's personal tank, including while offline → sell or showcase grown/rare fish → upgrade rod/tank/bait → catch rarer fish, hold more of them → unlock prestige/rebirth and new content over time.

One-sentence loop: **PLAYER CASTS & CATCHES → FISH GROWS (even offline) → SELL/SHOWCASE → UPGRADE → CATCH RARER FISH MORE EFFECTIVELY → UNLOCK MORE.**

### Why this concept (full detail in `docs/01_MARKET_RESEARCH.md` and `docs/02_CONCEPT_SCORING.md`)

Scored highest (126/150) of 21 researched concepts, ahead of idle-clicker (96) and vending-machine tycoon (94), with pure genre clones (garden-growing, pet-hatching, mining) explicitly disqualified from the shortlist per the brief's instruction to penalize undifferentiated clones despite their own raw scores (103, 92, 86). Wins on: near-zero required custom art (procedural part-built fish, no asset uploads), no combat/PvP/base-raiding (avoids the worst exploit surface of the trendy steal-tycoon genre), proven retention mechanic (idle+offline growth, same family as Grow a Garden's success) combined with a proven skill-loop (short active cast/reel, differentiated from *Fisch*'s deep skill-fishing focus), and additive (never punishing) monetization.

### Rejected concepts and why (see `docs/02_CONCEPT_SCORING.md` for full scoring table of all 21)
- Garden-growing / pet-hatching / mining clones — no differentiation from dominant incumbents (Grow a Garden, Pet Simulator, Mining Simulator); explicitly penalized per brief.
- Steal/PvP-tycoon hybrid (Steal a Brainrot-style) — highest exploit surface (raiding, dupes) of any concept considered.
- Anime fighting game — fastest-growing genre but high technical risk (netcode/balance) for solo dev.
- Horror co-op, tower defense, factory automation, dress-up competition, cozy roleplay — all scored lower on solo feasibility and/or art requirements; see scoring table.

## Business model (full detail in `docs/05_MONETIZATION.md`)

- Verified Sept 2026: DevEx cash-out = $0.0038/Earned Robux, 30,000 Robux minimum per cash-out request (~$114). Marketplace fee = 30% (developer keeps 70%). Net: **1 gross Robux spent by a player ≈ $0.00266 to the developer.**
- To hit $100/month: ~37,600 gross Robux/month in Game Pass + Developer Product sales needed.
- Revenue scenarios: Conservative (3,000 MAU, 1.5% conversion) ≈ $30/mo. Expected (5,000 MAU, 3% conversion) ≈ $120/mo — this is the realistic first-quarter target. Optimistic (15,000 MAU, 4% conversion) ≈ $559/mo.
- Monetization is entirely convenience/cosmetic: Game Passes (Auto-Fisher, 2x Coins, Extra Tank Room, VIP Rod) + Developer Products (Coin packs, Instant Growth, Rare Bait boost). Rarity odds are never sold directly — only time/space/appearance.

## Architecture (full detail in `docs/06_ARCHITECTURE.md`)

- **Toolchain:** Rojo project (`default.project.json` at repo root). No Studio-authored instances anywhere — the entire map (`MapBuilderService`) and all UI (`UIController` + friends) are built procedurally in Luau at runtime. This means the MVP needs **zero manual Studio building and zero asset uploads** to run — sync and press Play.
- **Data model:** Single DataStore (`PlayerData_v1`), one key per UserId. Rarity is decoupled from species (a multiplier applied on top of any species) so N species × M rarities gives N×M variety from N+M data rows — the lever for cheap future content.
- **Server-authoritative everywhere:** client only ever sends "I want to cast" / "I tapped now" / "sell this uid" / "buy this track" — every outcome (timing via server's own clock, RNG, cost, ownership) is computed server-side. Full adversarial review in `docs/07_TESTING.md`.

## File map (everything that exists right now)

```
default.project.json                              -- Rojo project definition

docs/
  01_MARKET_RESEARCH.md                            -- Phase 1: market snapshot, 21 concepts
  02_CONCEPT_SCORING.md                            -- Phase 2: full scoring table, top 3, final pick
  03_CORE_LOOP.md                                  -- Phase 3: loop validation, session-by-session hooks
  04_GAME_DESIGN_DOCUMENT.md                       -- Phase 4: full GDD, MUST/IMPORTANT/OPTIONAL split
  05_MONETIZATION.md                               -- Phase 5: products, revenue model, DevEx math
  06_ARCHITECTURE.md                               -- Phase 6: file tree, data model, remote protocol, security
  07_TESTING.md                                    -- Phase 8: adversarial code review + manual test checklist
  08_PRESENTATION.md                               -- Phase 10: name, icon/thumbnail concepts, copy
  09_LAUNCH_CHECKLIST.md                           -- Phase 11: exact manual steps for the user
  10_POST_LAUNCH_ITERATION.md                      -- Phase 12: funnel diagnosis framework

src/ReplicatedStorage/Shared/                      -- ModuleScripts, shared by client+server
  Constants.lua                                    -- ALL tunable numbers (cooldowns, growth time, caps, etc.)
  RemoteNames.lua                                   -- canonical remote name list
  RarityConfig.lua                                  -- 5 rarity tiers (Common..Legendary), weighted roll fn
  FishData.lua                                      -- 6 species (Minnow..Koi), weighted roll fn
  UpgradeConfig.lua                                 -- Rod/Tank/Bait cost curves + effect formulas
  FishModelFactory.lua                              -- builds a procedural (part-based) fish Model
  MonetizationIds.lua                               -- Game Pass / Dev Product IDs (PLACEHOLDERS = 0, see below)

src/ServerScriptService/
  Server.server.lua                                 -- bootstrap: wires every service in dependency order
  Services/
    RemoteSetup.lua                                 -- creates ReplicatedStorage.Remotes + RemoteEvents
    RateLimiter.lua                                 -- generic per-player-per-key cooldown backstop
    MapBuilderService.lua                           -- procedurally builds dock/water/spawn/tank-plot grid (24 plots)
    PlayerDataService.lua                           -- DataStore load/save w/ retry, offline growth, autosave, BindToClose
    FishingService.lua                              -- cast/reel state machine, server RNG, Auto-Fisher loop
    TankService.lua                                 -- growth ticking (online), selling
    ShopService.lua                                 -- Rod/Tank/Bait Coin-upgrade purchases
    MonetizationService.lua                         -- Game Pass ownership cache, Developer Product ProcessReceipt
    AnnouncementService.lua                          -- server-wide rare-catch broadcast
    DailyRewardService.lua                           -- 7-day login streak reward

src/StarterPlayer/StarterPlayerScripts/
  Client.client.lua                                 -- bootstrap: builds UI, wires all controllers
  Controllers/
    ClientState.lua                                  -- client mirror of server PlayerDataSync payload
    UIController.lua                                 -- builds ALL ScreenGui via code (HUD/Shop/Tank/Reel/Daily)
    FishingController.lua                            -- cast prompt + reel minigame + catch/announcement feedback
    TankRenderController.lua                         -- renders own fish as swimming procedural models in tank plot
    ShopController.lua                                -- Coin-upgrade rows + Game Pass/Product purchase buttons
    InventoryController.lua                           -- Coins label, sell list, daily reward popup
```

## Economy values as currently tuned (all in `Constants.lua` / `UpgradeConfig.lua` / `RarityConfig.lua` / `FishData.lua` — **untested against real players, expect to retune after first playtest**)

- Cast cooldown 1.5s, reel window 1.2s (perfect at 0.6s), timeout 4s.
- Fish growth: 20 minutes online to full maturity; offline growth capped at 8 hours credited.
- Starter tank: 6 slots, +2 per Tank level (max level 10 → 24 slots + Extra Tank Room pass +6).
- Rod/Tank/Bait costs: geometric curves (baseCost × growth^(level-1)), Rod ×1.6/lvl from 50, Tank ×1.55/lvl from 75, Bait ×1.5/lvl from 40. Max levels 10/10/5.
- Rarity weights (Common..Legendary): 60/25/10/4/1, gated by rod level (Legendary needs rod level 6+).
- 6 species (Minnow..Koi), base values 4–55 Coins, gated by rod level 1–4.
- Sell value formula: `baseValue × rarityMultiplier × (0.5 + 0.5×growth) × rodValueBonus × coinPassMultiplier`.
- Daily reward: 7-day escalating table (20/30/45/65/90/120/200 Coins), gentle reset (not punishing) on a missed day.

## Monetization IDs — ACTION REQUIRED BEFORE LAUNCH

`src/ReplicatedStorage/Shared/MonetizationIds.lua` has all Game Pass and Developer Product IDs set to placeholder `0`. **Nothing will grant correctly until the user creates the real products in the Creator Hub and fills in real IDs** — exact steps are in `docs/09_LAUNCH_CHECKLIST.md` step 3.

## Test status

**In-engine testing is underway** — the user has Rojo + Studio set up locally (a local `game test.rbxl` and `rojo.exe` exist in the working folder; both are gitignored as local artifacts, not part of the source). Three real crashes have been found by actually playing and fixed since the initial build:
1. `Server.server.lua` referenced `script.Services` instead of `script.Parent.Services` — fixed (commit `551ae3e`).
2. Dock/water/cast-spot part placement let players fall into the water / cast spot was positioned past the dock's edge — fixed (commit `02825d9`).
3. `UIController` set a nonexistent `ScreenGui.ResetOnSpawnGui` property, which crashed client UI construction — fixed (commit `d1de7b3`); the reel bar also gained a visible "perfect" target-zone marker since (commit `ccf8a92`).

**Session 2 (this session):** did a complete line-by-line re-review of every file in `src/` (all Shared modules, all server Services, all client Controllers) specifically hunting for the same class of bug that caused the three fixes above (invalid/misspelled Roblox API members, Rojo path mismatches, nil-handling gaps). No new bugs found — every remote handler still validates payload shape, every service still recomputes costs/ownership server-side, and no other suspicious API member names were found. Treat this as "passed static re-review," not "passed live testing" — the manual checklist in `docs/07_TESTING.md` still needs to be run end-to-end by the user and is the higher-value next step.

## Known bugs

None currently open. The three found via live playtesting (above) are fixed. Nothing else has been confirmed against a live server yet — keep working through the manual checklist in `docs/07_TESTING.md` and report the exact Output-window error text for anything that breaks; that's the fastest path to a fix.

## Incomplete / deferred features (by design, see `04_GAME_DESIGN_DOCUMENT.md` MUST/IMPORTANT/OPTIONAL split)

Not built yet, intentionally, to keep MVP scope tight:
- Second biome/dock, achievements/badges, cosmetics (tank décor, rod skins), player trading, rebirth/prestige, friends-only leaderboard, entering another player's tank room, custom AnalyticsService events.
- These are the natural "IMPORTANT (post-validation)" backlog — build them only after the manual test checklist passes and the core loop is confirmed fun in actual play, not before.

## Immediate next action

1. **User:** Rojo sync is already working (three live-play crashes have been caught and fixed). Keep working through the manual test checklist in `docs/07_TESTING.md` — multiplayer (2+ clients), reconnection/offline-growth, and the exploit-probing section haven't been explicitly confirmed yet as of this session.
2. **Report back** the exact Output-window error text for anything that breaks (fastest path to a fix), and separately, how the core loop *feels* — pacing (reel window, growth time) is the most likely thing to need retuning after more hands-on play.
3. Once the core loop is confirmed fun and functional, proceed to `docs/09_LAUNCH_CHECKLIST.md` steps 3+ (create real Game Passes/Developer Products, fill in `MonetizationIds.lua`, publish).
4. After real players arrive, use `docs/10_POST_LAUNCH_ITERATION.md`'s funnel framework rather than guessing at new features.

## Local dev artifacts (not in git)

`game test.rbxl` (the user's local Studio save synced via Rojo) and `rojo.exe` (the Rojo CLI binary) exist in the working folder but are gitignored (`.gitignore` added session 2) — they're local tooling, not game source, and don't belong in version control (rojo.exe alone is ~15MB).

## If resuming this project fresh (for another model/session)

Read, in order: this file → `docs/04_GAME_DESIGN_DOCUMENT.md` (what the game is) → `docs/06_ARCHITECTURE.md` (how it's built) → the actual `src/` code. The docs in `docs/01` through `docs/10` are numbered in the order the original brief's phases were executed and each is self-contained if you need the full reasoning behind a decision rather than just this summary.
