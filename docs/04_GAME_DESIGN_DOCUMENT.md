# Phase 4 — Game Design Document: *Fish Tank Simulator*

MVP-first. Every section is split into **MUST HAVE (launch)**, **IMPORTANT (post-validation)**, and **OPTIONAL (future)**. Nothing in IMPORTANT or OPTIONAL should be built before the MUST HAVE game works end-to-end and is fun.

## CORE LOOP
See `03_CORE_LOOP.md`. One line: cast → catch → tank grows (incl. offline) → sell/showcase → upgrade → repeat with rarer fish and more space.

## PLAYER PROGRESSION
- **MUST HAVE:** Rod level (1–10 for launch), Tank level/capacity (starter 6 slots → upgrades add slots), Coins as the single currency.
- **IMPORTANT:** Prestige/"Rebirth" system — reset Coins + rod/tank tier for a permanent global sell-price multiplier and an exclusive rebirth-only cosmetic.
- **OPTIONAL:** Skill tree/branching upgrade paths, seasonal battle-pass-style progression track.

## ECONOMY
- **MUST HAVE:** Coins (earned by selling fish, spent on rod/tank/bait upgrades and tank-slot expansion). Sell prices scale with fish rarity × size. Prices for upgrades scale geometrically (roughly ×1.5–1.6 per tier) so early upgrades are cheap and frequent, later ones are meaningful goals.
- **IMPORTANT:** Rare Bait as a semi-premium consumable (earnable slowly for free, purchasable for Robux) that temporarily raises rare-fish odds.
- **OPTIONAL:** A second premium-only currency (Pearls) for cosmetics only — deliberately deferred; one currency is simpler to balance and explain for launch, and the brief explicitly warns against unnecessary systems.

## MAP / WORLD DESIGN
- **MUST HAVE:** One small hub area: a dock (casting zone) + a personal tank room per player (instanced via a private area or a player-owned tank model that only the owner can enter/decorate, visible to others from outside). Roblox-native terrain/parts only, no imported environment assets.
- **IMPORTANT:** A second biome/dock unlocked at a mid-tier rod level (different fish pool, reskinned water color and dock props built from parts).
- **OPTIONAL:** Additional biomes (3rd, 4th...), a "visit a friend's tank room" teleport system, seasonal biome reskins (e.g., a Halloween palette swap).

## MULTIPLAYER MECHANICS
- **MUST HAVE:** Standard shared Roblox server — players see each other at the dock and can see each other's tank rooms from outside (read-only visibility, not entry, for MVP simplicity/security).
- **IMPORTANT:** Direct player-to-player trading of fish (server-validated, see `06_ARCHITECTURE.md` for anti-dupe design). Server-wide announcement on a rare catch.
- **OPTIONAL:** Visiting/entering a friend's tank room, cooperative "biome events" (e.g., a temporary shared rare-fish surge server-wide).

## SOCIAL FEATURES
- **MUST HAVE:** Visible tank rooms (passive show-off), server rare-catch announcements.
- **IMPORTANT:** Trading, a simple friends-only leaderboard view.
- **OPTIONAL:** Guilds/clubs, cross-server leaderboard, gifting.

## REWARDS
- **MUST HAVE:** Fish (the core reward), Coins, rod/tank upgrades.
- **IMPORTANT:** Daily login reward (small, escalating over a 7-day cycle, resets gently rather than punishing a missed day), rotating daily "featured species" bonus odds.
- **OPTIONAL:** Weekly/monthly challenges, seasonal event currency and event-exclusive fish.

## DAILY / RETURNING PLAYER SYSTEMS
- **MUST HAVE:** Offline growth calculation on login (fish continue maturing while the player is away, capped at 8 hours of credited offline time so idling for days doesn't trivialize progression).
- **IMPORTANT:** Daily login streak reward, daily featured-species bonus.
- **OPTIONAL:** Weekly reset "collection goals," push-style in-experience reminders via Roblox's own notification tools (no external services).

## COSMETICS
- **MUST HAVE:** None required to launch — deferred to keep MVP scope tight, but the architecture (a `cosmeticId` field on tank/rod data) is designed in from day one so cosmetics can be added later without a data migration.
- **IMPORTANT:** Tank-room décor items (purchasable with Coins or Robux, purely visual), rod skins.
- **OPTIONAL:** Player avatar accessories (fishing hat, etc.), animated tank backgrounds.

## ACHIEVEMENTS
- **IMPORTANT (not MUST, but cheap and high-value — bump up if time allows):** A short list (10–15) of simple milestones (first catch, first shiny, first rebirth, tank fully upgraded, catch N total fish) each granting a small Coin reward. Cheap to build (one data table + one check function), meaningfully improves the "why keep playing" feeling.
- **OPTIONAL:** Roblox platform Badges integration (visible on the player's profile — free virality via profile visibility) — genuinely worth doing early since it's a few lines of code against Roblox's free `BadgeService`, but is not gameplay-blocking, so it's listed here rather than MUST HAVE.

## ONBOARDING
- **MUST HAVE:** A single glowing "Cast!" prompt at spawn, 3–4 short tutorial tooltips (cast, sell, shop, tank), no forced dialogue/cutscenes.
- **IMPORTANT:** A skippable one-time popup explaining rarity tiers with a visual chart.
- **OPTIONAL:** Full guided-tour NPC, video-style tutorial.

## UI
- **MUST HAVE:** Coin counter, Cast button/prompt, Shop menu (rod/tank/bait upgrades), Inventory/Tank view, minimal reel-minigame bar.
- **IMPORTANT:** Leaderboard panel, Trade window, Daily reward popup, Settings (mute music/SFX).
- **OPTIONAL:** Full codex/collection book UI, animated rarity reveal cutscenes.
- All UI built mobile-first (see Technical section) since a large share of Roblox traffic is mobile/tablet.

## AUDIO
- **MUST HAVE:** A cast sound, a catch/reward sound (pitched up for rarer fish), ambient water/dock loop. Use only royalty-free or Roblox's built-in catalog audio IDs the user has rights to use — the user must select/approve actual audio IDs in Studio (see Launch Checklist).
- **IMPORTANT:** Distinct rarity-tier catch jingles, background music loop.
- **OPTIONAL:** Full original score, biome-specific ambience.

## DATA SAVING
- **MUST HAVE:** Roblox `DataStoreService` with retry/backoff, autosave on an interval, save-on-leave, `BindToClose` handling, and offline-time tracking for growth calculation. See `06_ARCHITECTURE.md` for the full reliability design.
- **IMPORTANT:** A lightweight backup/versioning key (secondary DataStore write) to recover from a corrupted primary save.
- **OPTIONAL:** Cross-experience data (e.g., a companion "codex" mini-experience) — explicitly out of scope; adds infra complexity for little payoff at this stage.

## MONETIZATION
See `05_MONETIZATION.md` for full detail. Summary: Game Passes (Auto-Fisher, 2x Coins, extra tank room, VIP rod skin) + Developer Products (Coin packs, Instant Growth potion, Rare Bait pack). All convenience/cosmetic, none pay-to-win (rarity odds are never sold directly, only *time* and *space*).

## ANALYTICS
- **MUST HAVE:** Roblox's built-in analytics (Creator Hub → Analytics: visits, retention D1/D7/D30, playtime) — free, first-party, no external service needed.
- **IMPORTANT:** A handful of custom events via Roblox's free `AnalyticsService` (`LogOnboardingFunnel`, `LogEconomyEvent`) to see exactly where players drop off in onboarding and which purchases convert.
- **OPTIONAL:** External dashboards — explicitly rejected; violates the "no external services" constraint and Roblox's own analytics are sufficient at this scale.

## FUTURE UPDATE PATH
Cheap, repeatable content the solo dev can ship on a sustainable cadence:
1. New fish species (recolor/rescale of existing procedural fish + one data-table row) — weekly/biweekly.
2. New biome (new dock skybox/water color + a themed fish pool) — monthly.
3. Limited-time event fish tied to real-world seasons (cheap re-use of the species system).
4. New tank décor cosmetics.
5. Achievements/badges expansion.
6. Only after all of the above: consider a second premium currency, guilds, or entering friends' tanks — bigger systems, only worth it once the core game has proven retention.

## Explicitly rejected for MVP (and why)
- **Custom imported 3D fish/asset models:** requires Studio asset upload + moderation review before the user can even test; procedural part-built fish achieve an acceptable "low-poly toy" look at zero asset pipeline cost and zero moderation wait. Real meshes are a good *post-launch* polish investment once revenue justifies commissioning art.
- **PvP/base-raiding mechanics:** highest exploit surface (duplication, griefing) of any concept considered; deliberately avoided per the core constraints.
- **Second premium currency at launch:** unnecessary complexity for an MVP; one currency is easier for new players to understand and easier for the solo dev to balance.
- **Guild/clan systems:** valuable eventually, meaningful engineering and moderation surface (chat, membership, group currency) that isn't needed to validate the core loop.
