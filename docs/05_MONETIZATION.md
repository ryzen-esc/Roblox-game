# Phase 5 — Monetization & Revenue Model

## Design principle

Every purchasable item makes a loop the player already enjoys **faster, bigger, or prettier** — never something that makes the free experience deliberately worse to create pressure. Rarity (the game's core "chase" feeling) is never sold directly; only *time* (growth speed, auto-fishing) and *space* (tank slots) and *appearance* (cosmetics) are for sale. A player who never spends a Robux can catch every species and reach every rarity tier — they'll just do it more slowly and with more manual clicking.

## Products (MUST HAVE at launch)

**Game Passes** (one-time per player):
| Pass | Suggested price | What it does |
|---|---|---|
| Auto-Fisher | 199 Robux | Automatically casts/reels every ~8 seconds without manual input. Convenience, not power — still bound by the same rarity odds and tank capacity as everyone else. |
| 2x Coins | 149 Robux | Doubles Coins earned from selling fish. Speeds up progression; does not change rarity odds. |
| Extra Tank Room | 249 Robux | Unlocks one additional tank room beyond what's earnable for free, for players who want a bigger showcase without grinding tank-level Coin costs. |
| VIP Rod Skin + Perk | 179 Robux | Cosmetic rod skin + a slightly wider reel-timing window (helps consistency, not a rarity change). |

**Developer Products** (repeatable):
| Product | Suggested price | What it does |
|---|---|---|
| Small / Medium / Large Coin Pack | 99 / 249 / 599 Robux | Direct Coin purchase for players who'd rather skip grinding for an upgrade they want now. |
| Instant Growth Potion | 79 Robux | Instantly matures one fish to full size. Time-skip, not a rarity change. |
| Rare Bait Pack (30 min boost) | 129 Robux | Temporarily raises rare-fish odds for half an hour — a boost, not a guarantee, and available to earn for free in small amounts via achievements/dailies (IMPORTANT tier). |

All prices are starting points — see `09_LAUNCH_CHECKLIST.md` for A/B-style price tuning after real player data comes in.

## What's deliberately NOT sold
- Guaranteed rare/legendary fish (would be straightforward pay-to-win and undermines the entire chase loop).
- Anything that makes the free tank smaller or slower than what the game *shows* a new player at spawn (no bait-and-switch).
- Loot boxes with real-money-priced randomized high-value outputs (Rare Bait *odds boosts* are fine; a "mystery crate that might contain a legendary fish for 500 Robux" is not — too close to gambling mechanics Roblox and regulators scrutinize).

## Revenue model

**The math that everything below is built on** (verified against current Roblox documentation, Sept 2026):
- Marketplace fee: Roblox takes 30% of Game Pass / Developer Product sales → developer keeps **70%** of the Robux price.
- DevEx cash-out rate: **$0.0038 per Earned Robux** (standard rate).
- Combined: **1 gross Robux spent by a player → $0.00266 to the developer after cash-out.**
- DevEx also requires a minimum balance of 30,000 Earned Robux (~$114) per cash-out request — so in practice, revenue accumulates and gets cashed out in batches, not smoothly every single month at first.

To net **$100/month**, the game needs approximately:
$100 ÷ $0.00266 ≈ **37,600 gross Robux/month** in combined Game Pass + Developer Product sales (roughly 1,250 Robux/day on average).

### Scenario model

Revenue ≈ MAU × payer conversion rate × average Robux spent per paying player.

| Scenario | Monthly Active Users (MAU) | Payer conversion | Paying players | Avg. spend/payer (Robux) | Gross Robux/month | Net $/month (after 70% + DevEx) |
|---|---|---|---|---|---|---|
| **Conservative** | 3,000 | 1.5% | 45 | 250 | 11,250 | **≈ $30** |
| **Expected** | 5,000 | 3% | 150 | 300 | 45,000 | **≈ $120** |
| **Optimistic** | 15,000 | 4% | 600 | 350 | 210,000 | **≈ $559** |

Notes on the assumptions:
- 1.5–4% payer conversion is a conservative-to-typical range for casual Roblox simulators (industry rule-of-thumb; actual figures aren't publicly audited, treat as an estimate).
- 250–350 average Robux spent per payer per month assumes most paying players buy 1–2 items (e.g., Auto-Fisher once, then an occasional Coin pack), not whales — consistent with a low-pressure, non-predatory monetization design.
- MAU figures assume the game is discoverable at all — see the CCU note below for what that requires practically.

### What MAU actually requires

Roblox's discovery algorithm favors experiences with steady concurrent players (CCU) and healthy retention, not just raw visit spikes. As a rough planning heuristic, a small simulator sustaining **50–150 average concurrent players** in its first weeks (achievable with a clear icon/thumbnail, a functioning core loop, and consistent small updates) typically corresponds to a MAU in the low thousands — i.e., the "Conservative" to "Expected" rows above are realistic first-quarter targets, not aspirational ones. The "Optimistic" row requires either a genuine viral moment (a TikTok/YouTube creator playing it) or several months of consistent update cadence building an audience — plan for it, don't bet on it.

### Milestone ladder (Phase 13 target, restated)
1. First Robux from a real player (proves the shop UI and purchase flow work).
2. 100 Robux total.
3. 1,000 Robux total.
4. 5,000 Robux total.
5. 10,000 Robux total.
6. 30,000+ Earned Robux/month sustained → first DevEx cash-out (~$114+), i.e., the "$100/month" milestone in practice.

Revenue is not guaranteed — this model exists to guide product decisions (which features to prioritize, when a price is too high/low, whether conversion or traffic is the bottleneck), not as a promise.
