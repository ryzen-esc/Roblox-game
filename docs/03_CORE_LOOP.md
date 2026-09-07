# Phase 3 — Core Loop Validation

## The loop, in one sentence

**Player CASTS a line to CATCH a fish → the fish lives and GROWS in the player's personal tank (even while offline) → the player SELLS or SHOWCASES grown/rare fish → proceeds UPGRADE the rod, bait, and tank → better gear catches RARER fish faster and holds MORE of them → new tank rooms, biomes, and prestige tiers unlock.**

Restated in the requested structure:

> PLAYER CASTS & CATCHES → EARNS FISH (a growing asset, not just currency) → UPGRADES ROD/TANK → CAN CATCH RARER FISH MORE EFFECTIVELY → UNLOCKS NEW BIOMES, TANK ROOMS, AND PRESTIGE.

## Session-by-session validation

**First 30 seconds:** Player spawns on a small dock. A glowing prompt reads "Press to Cast." One tap starts a short reel minigame (a moving marker crosses a bar; tap again in the highlighted zone). Within 10–15 seconds the player has caught their first fish, which visibly swims from the rod into their starter tank. Immediate, legible cause → effect.

**First 5 minutes:** Player catches 4–6 more fish, fills the starter tank's few slots, and sees a tutorial nudge toward the Shop. First rod upgrade is cheap and immediately felt (faster reel window, wider catch-zone). A rare "shiny" (recolored, particle-trailed) fish variant appears in the catch pool — the chase hook is planted early, not after a grind wall.

**First 20 minutes:** Tank fills up, forcing a real decision: sell fish for Coins, or pay to expand the tank. First tank-room unlock or biome unlock lands around here (a new dock area with better base fish). A first shiny/mutated catch by *any* player on the server triggers a small server-wide announcement — social proof that pulls other players toward the dock and plants a FOMO hook for the catcher's own next session.

**First hour:** Multiple tank rooms exist. Auto-Fisher (a purchasable convenience, not a hard requirement) becomes visible as "the thing serious players have." A basic leaderboard (rarest fish / biggest fish on the server) gives a comparison point. A first trade with another player is plausible if a friend is also playing.

**First return session (next day):** Fish grew overnight (offline growth, capped — see `04_GAME_DESIGN_DOCUMENT.md`), so logging back in shows visible progress the player didn't have to sit and watch happen. A daily login reward and a rotating "featured rare fish" (better odds for one specific species that day) give a concrete reason to open the game today specifically, without punishing a missed day.

**Long-term:** A prestige/"rebirth" system resets Coins and rod/tank tiers in exchange for a permanent multiplier and an exclusive cosmetic (tank skin or fish variant only rebirthed players can have). New fish species and biome reskins ship every 1–3 weeks — cheap to produce because they're recolors/rescales of the existing procedural fish system, not net-new art.

## Why each moment is satisfying

- **Moment-to-moment:** the cast → reel → catch cycle is short (10–20 seconds), has a clear skill component (timing), and always ends in visible feedback (a fish physically swimming into the tank) — never a silent number-only reward.
- **Join:** the very first action is understandable without reading anything — a glowing prompt and a single button.
- **Stay 5 more minutes:** the shop and tank-slot pressure create an immediate small decision loop; rarity variance means "one more cast" is always plausible.
- **Play another round tomorrow:** offline growth + daily rotation give a reason to open the app *today*, not just "eventually."
- **Invite a friend:** showcase tanks are visible to other players in the same server; trading requires another human, which is an organic multiplayer/social pull.
- **Eventually spend Robux:** every purchasable item removes friction from a loop the player already enjoys (more tank space, faster growth, an auto-fisher) rather than gating the loop itself. See `05_MONETIZATION.md`.

## Risk check

The two things that could break this idea: (1) if catching/growing fish feels like *waiting*, not *playing* — mitigated by keeping the active minigame short and skill-expressive rather than idle-only; (2) if procedural (non-imported) fish models look too cheap to be visually satisfying — mitigated by leaning into a deliberately simple, colorful "low-poly toy" aesthetic (see `08_PRESENTATION.md`) rather than trying to fake realism, and by treating real mesh imports as a funded post-validation upgrade, not an MVP blocker.
