# Phase 1 — Market Research

Research date: September 2026. Sources are web searches performed during this session (live Roblox charts, DevEx documentation, industry blogs). Treat all player-count/visit figures as directional, not exact.

## 1. Current market snapshot (Sept 2026)

**Top by live concurrent players / all-time visits:**
- *Steal a Brainrot* — tycoon base-building + steal/defend PvP + meme aesthetic. Breakout hit of mid-2025, still dominant.
- *Grow a Garden* — idle plant-growing loop (plant → wait → harvest → sell → buy better seeds) wrapped in social trading and rare "mutations." Hundreds of millions of visits. Currently the most-copied loop on the platform.
- *Blox Fruits*, *Adopt Me!*, *Murder Mystery 2*, *Brookhaven RP* — long-running incumbents with years of content investment and huge established social graphs. Not realistically catchable by a solo dev.
- *Fisch* — skill-based fishing across biomes/bosses. Very well executed, effectively owns the "fishing" keyword on Roblox search.
- *DOORS*, *99 Nights in the Forest*, *Forsaken* — co-op/solo horror. Best-in-class session length, but saturated at the top and horror requires tension pacing that's hard to nail solo.
- *Tower of Hell* — obby genre leader. Obby is easy to build but incredibly saturated and has weak monetization ceilings (mostly cosmetic-only, high churn).

**Fastest-growing genre:** anime-style/fighting games (*Deepwoken*, *Blade Ball* and clones) — high player interest, but high technical risk for a solo dev (hit registration, combat balance, netcode) and an arms race of PvP content updates.

**Highest-volume genre by raw count of top-100 games:** tycoons and simulators/idle-collectors. This is the most "solved" genre for solo developers: the loop (do action → earn currency → buy upgrade → do action better) is simple to build, cheap to reskin, and Roblox's install base has been trained for a decade to understand it instantly.

## 2. Roblox economics (verified against current sources)

- **DevEx cash-out rate:** $0.0038 per Earned Robux (standard rate, as of the Sept 2025 rate increase). A higher $0.0054 rate exists only for age-verified 18+ US players' spend from June 2026 onward — not something to design around for a general-audience game.
- **Minimum DevEx cash-out:** 30,000 Earned Robux (~$114) per request. This matters: hitting "$100/month" in practice means accumulating Earned Robux and cashing out periodically, not a smooth $100 every month unless volume is consistent.
- **Marketplace fee:** flat 30% on Game Passes and Developer Products — developers keep 70% of the Robux price.
- **Net effective rate:** 1 gross Robux spent by a player → $0.7 × $0.0038 ≈ **$0.00266** to the developer after both cuts. This is the number the whole revenue model in `05_MONETIZATION.md` is built on.

## 3. What players complain about (from community/genre patterns)

- Idle/simulator games: "pay-to-win," inventory/tank caps that force purchases instead of gameplay decisions, confusing UI, offline-progress caps that feel stingy.
- Tycoon/steal-PvP games: griefing, exploiters duplicating currency, base-raiding frustration for new/undefended players.
- Horror co-op: too short (one playthrough and done), or too reliant on jump-scares with no real skill expression.
- Fishing games: grind fatigue once the "new rod" dopamine hits diminishing returns; sameness of biomes.
- General: intrusive purchase popups, fake "limited time" pressure, currency systems opaque enough that players can't tell what a purchase is actually worth.

These are directly addressed in the monetization design (Phase 5): no purchase popups outside a shop menu the player opens themselves, no fake scarcity, inventory caps solved by *both* free progression and paid convenience (not a free-play brick wall).

## 4. Twenty candidate concepts

Spanning genres, not just simulators, per the research brief:

1. **Aquarium/fish-collector idle-sim** — catch fish (quick active minigame) → fish live and grow in a personal tank (idle, including offline) → sell/showcase/trade → upgrade rod & tank.
2. Garden/crop-growing simulator (Grow a Garden clone) — saturated, no differentiation.
3. Pet-hatching simulator (egg → hatch → collect → trade) — saturated (Pet Simulator franchise).
4. Mining/gem-cave simulator (dig → sell → upgrade pickaxe) — saturated (Mining Simulator franchise).
5. Cooking/restaurant tycoon (take orders, serve, upgrade restaurant) — evergreen but crowded, needs constant menu content.
6. Obby with cosmetic checkpoint rewards (Tower of Hell-style) — trivial to build, but weak monetization ceiling and brutal saturation.
7. Co-op horror survival (escape entities, procedural rooms) — great session length, but top of genre is dominated by well-funded teams; tension design is hard to get right solo.
8. Tycoon + steal/defend PvP hybrid (Steal a Brainrot-style) — trendy, but high exploit surface (raiding, dupes) and meme-dependent longevity risk.
9. Anime-style combat/fighting game (Blade Ball-style) — fastest-growing genre, but high technical risk (hit reg, balance) for one developer.
10. Vending-machine placement tycoon (place machines around a map, collect passive revenue, upgrade) — novel light-tycoon niche, low saturation.
11. Idle factory/conveyor automation sim — fun on other platforms, but conveyor/physics networking adds real technical risk.
12. Fashion/dress-up competition (Dress to Impress-style) — proven social genre, but needs a large and constantly refreshed cosmetic library (heavy art burden — explicitly against constraints).
13. Round-based "Escape the X" obby/puzzle — saturated, low differentiation, weak monetization.
14. Tower defense (place towers, survive waves, co-op) — proven genre, moderate complexity (pathfinding/wave balance), decent monetization.
15. Clicker/idle "empire" (click to earn, buy upgrades, prestige) — simplest possible build, very low technical risk, but done to death and hard to differentiate visually.
16. Museum/collection showcase builder (collect items from other activities, display them, other players rate your museum) — interesting meta-layer, but needs another game system feeding it content.
17. Racing/parkour "speed simulator" (collect speed boosts, race obby, cosmetic pets/trails) — proven, but leaderboard-chasing alone has weaker retention than a persistent economy.
18. Cozy life-sim/roleplay hangout (Brookhaven-style) — saturated, and needs a large furniture/house asset library (heavy art burden).
19. Idle dungeon-crawler auto-battler (place heroes, auto-fight waves, gacha-lite) — proven idle-RPG genre, but needs an ever-growing roster of enemies/heroes to stay fresh (content treadmill).
20. Round-based heist minigame ("Steal the Diamond"-style) — fun in short bursts, but no persistent economy to monetize deeply.
21. Storm-chasing/vehicle sim (drive to storms, sell footage, upgrade vehicle) — niche appeal, vehicle physics adds technical risk, higher art needs (vehicles).

Concept #1 (Aquarium/fish-collector idle-sim) is carried into scoring in `02_CONCEPT_SCORING.md` alongside two other finalists.

Sources consulted: Roblox Creator Hub DevEx docs (create.roblox.com/docs/production/monetization/developer-exchange), Roblox marketplace fee docs (create.roblox.com/docs/marketplace/marketplace-fees-and-commissions), rblxdb.com live charts, and multiple 2026 Roblox trend roundups (exitlag.com, game-ace.com, studiokrew.com).
