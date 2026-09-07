# Phase 12 — Post-Launch Iteration Framework

Once real players are in the game, prioritize evidence over guessing. Roblox's own Creator Hub Analytics tab (free, first-party, no setup beyond publishing) gives impressions, clicks, joins, playtime, and retention (D1/D7/D30) out of the box.

## The funnel

```
IMPRESSION → CLICK → JOIN → UNDERSTAND → ENJOY → CONTINUE → RETURN → SPEND
```

Diagnose whichever stage is weakest and fix *that*, rather than adding random new features:

| Symptom | Likely stage | Fix |
|---|---|---|
| Low click-through on high impressions | Icon/thumbnail/title | Revisit `docs/08_PRESENTATION.md` concepts — try a different thumbnail emphasis (action shot vs. collection shot) before touching gameplay. |
| Joins happen but players leave in under a minute | Onboarding/core gameplay | Check whether the first cast happens fast enough, whether the tutorial tooltips are clear, whether the game visibly explains itself in the first 30 seconds (see `03_CORE_LOOP.md`). |
| Decent session length, poor day-2 return rate | Progression/return hooks | Is offline growth actually rewarding on return? Is the daily reward visible and worth claiming? Revisit `Constants.GROWTH_TIME_SECONDS` and `OFFLINE_GROWTH_CAP_SECONDS`. |
| Good retention, weak monetization | Shop/product fit | Are the Game Passes/Developer Products actually appealing, or priced wrong? Which ones convert at all? (Check per-product purchase counts in Analytics.) Adjust price or description before adding new products. |

## What to track specifically (beyond Roblox's defaults)

If time allows, add a small number of custom `AnalyticsService` events (free, first-party) rather than reaching for an external tool:
- Onboarding funnel: fired-first-cast, fired-first-catch, fired-first-sale, fired-first-shop-open.
- Economy: which upgrade track gets bought first, how often Coins packs sell vs. Game Passes.

This is explicitly deferred past MVP (see `04_GAME_DESIGN_DOCUMENT.md`'s Analytics section) — add it once the core loop is confirmed to work, not before.

## Business milestone ladder (restated from `05_MONETIZATION.md`)

1. First Robux from a real player.
2. 100 → 1,000 → 5,000 → 10,000 Robux total.
3. 30,000+ Earned Robux/month sustained (the practical shape of "$100/month," given the DevEx minimum cash-out threshold) → first DevEx request.

## Rule for this phase

If a stage of the funnel is weak, fix that stage. Don't add a rebirth system because retention is bad if the actual problem is a confusing first 30 seconds — trace the funnel first, then act.
