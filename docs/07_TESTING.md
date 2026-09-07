# Phase 8 — Testing

## Important limitation of this session

This code was written and reviewed in a text-only environment with no access to Roblox Studio or the Roblox client, so **nothing here has been run in-engine yet.** Everything below is (a) a static adversarial code review of every remote-facing code path, treating every client as hostile per the brief, and (b) a manual test script for the user to actually execute in Studio, since that step genuinely requires a human at a keyboard (per the task's own list of things that require the user).

## Adversarial code review (assume every client is modified/hostile)

Walked through every remote handler asking "what's the worst input/timing a hacked client could send here, and does the server care?"

| Attack | Where | Result |
|---|---|---|
| Spam `CastRequest` as fast as possible | `FishingService.onCastRequest` | Blocked by `RateLimiter` (1.5s/cast) *and* by the `pendingAttempts[userId]` guard, which refuses a second cast while one is already active — both checks are independent, so bypassing one still hits the other. |
| Fire `ReelAttempt` without ever calling `CastRequest` | `FishingService.onReelAttempt` | `pendingAttempts[userId]` is nil → handler returns immediately. No fish, no side effects. |
| Fire `ReelAttempt` many times during one active cast | same | Only the first resolves (it nils out `pendingAttempts[userId]`); every subsequent call in the same window finds no pending attempt and no-ops. |
| Fire `ReelAttempt` after the 4s timeout already resolved it as a miss | same | Token check (`pending.token ~= token`) plus the fact that the timeout already cleared `pendingAttempts[userId]` means a late tap is a no-op — it cannot "steal" a second catch. |
| Send garbage/extra fields in any remote payload | all handlers | Every handler either takes no payload or explicitly checks `type(payload) == "table"` and the specific field types it expects before using them. Unexpected shapes are ignored, not errored into a crash. |
| Claim a fish by a fabricated `uid` in `SellFishRequest` | `TankService.onSellFishRequest` | Looked up in the player's own authoritative `data.fish` table; a non-existent uid finds nothing and pays nothing. |
| Spam `SellFishRequest{all=true}` to sell the same fish twice | same | The table is emptied on the first call (Lua removes each key as it's sold); a second near-simultaneous call iterates an empty table and earns 0. This is only race-free because the handler never yields between reading and mutating — confirmed by inspection: no `task.wait`/DataStore call sits between checking `data.fish` and clearing it. |
| Send a fabricated price in `BuyUpgradeRequest` | `ShopService.onBuyUpgradeRequest` | The client sends only *which track*; cost is always recomputed from `UpgradeConfig` + the player's current authoritative level. There is no field the client can use to influence the price. |
| Buy the same upgrade level twice by firing the remote twice instantly | same | `data[field]` is incremented synchronously in the same non-yielding call that deducts Coins — the second call (whenever it runs) sees the already-incremented level and recomputes a new (higher) cost. No double-purchase is possible without an intervening yield, and there isn't one. |
| Claim the daily reward multiple times same day | `DailyRewardService.onClaimDailyReward` | Guarded by `hoursSince < Constants.DAILY_RESET_HOURS` computed from the server-persisted `lastClaimUnix`, not anything client-supplied. |
| Replay a Developer Product receipt (Roblox's own at-least-once delivery) | `MonetizationService.processReceipt` | Checked against `data.processedReceipts`, which is now **force-saved synchronously before returning `PurchaseGranted`** (fixed during this review — see below) rather than waiting for the next periodic autosave, closing the crash window where a paid purchase could otherwise be silently lost or reprocessed. |
| Claim ownership of a Game Pass without buying it | `MonetizationService.ownsPass` | Never trusts a client claim — ownership is fetched from `MarketplaceService:UserOwnsGamePassAsync` (Roblox's own authoritative source) on join and refreshed via the server-only `PromptGamePassPurchaseFinished` event. |
| Manipulate the client-rendered reel-timing bar to always "look" perfect | `FishingController` (client) | Purely cosmetic. The server measures `os.clock()` itself from when it sent `CastStarted` to when it received `ReelAttempt` — the client's own animation, framerate, or a modified client claiming a different time has no channel to influence this; the server never reads a client-supplied timestamp. |
| Grow fish faster than intended by manipulating client clock | growth system | Growth is computed entirely server-side (`TankService`'s tick loop and `PlayerDataService`'s offline-growth-on-load), both using `os.time()`/`os.clock()` on the server. The client only *displays* `growth` from the last sync. |

**Two real issues found and fixed during this review:**
1. `MonetizationService.processReceipt` recorded a Developer Product as processed in the player's in-memory data and relied on the next periodic autosave (up to 120s later) to persist it. A server crash in that window could lose a paid purchase. Fixed by calling `PlayerDataService.save(player)` synchronously before returning `PurchaseGranted`, per Roblox's own guidance for `ProcessReceipt`.
2. `PlayerDataService`'s `game:BindToClose` handler saved every player using the normal 5-retry exponential-backoff path (worst case: tens of seconds per player). Roblox gives shutdown a limited total time budget shared across all players, so on a server with many players and a flaky DataStore moment, this could exhaust the budget on early players and leave later ones unsaved. Fixed by adding `PlayerDataService.saveForShutdown`, a 2-retry variant used only from `BindToClose`.

**Known accepted risk (not fixed, documented):** if the server crashes in the few hundred milliseconds *during* that forced save itself (after Roblox marks the receipt fulfilled but before the DataStore write lands), the grant could still be lost. This is an inherent limit of any DataStore-backed system and matches what Roblox's own documentation describes as the practical floor for `ProcessReceipt` reliability — not something a solo developer can fully eliminate.

## Manual test checklist (requires the user, in Roblox Studio)

Run these after following the Rojo sync steps in `09_LAUNCH_CHECKLIST.md`. Check each box as you verify it; log failures in the Bug List below (or the running one in `PROJECT_STATE.md`).

**Basic flow**
- [ ] Join the game (Play button in Studio). Confirm the dock, water, and a tank plot appear with no errors in the Output window.
- [ ] Walk to the glowing cast spot, confirm the "Cast Line" prompt appears and is triggerable.
- [ ] Cast, confirm the reel bar appears and the tap window feels fair (not too fast/slow — tune `Constants.REEL_WINDOW_SECONDS`/`PERFECT_REEL_SECONDS` if not).
- [ ] Catch a fish, confirm it visually appears swimming in your tank plot within a few seconds.
- [ ] Open the Tank panel, confirm the fish is listed with a Sell button; sell it and confirm Coins increase and the fish disappears from both the list and the 3D tank.
- [ ] Open the Shop panel, buy a Rod upgrade, confirm Coins decrease by the shown cost and the level display updates.
- [ ] Fill the tank to capacity, confirm casting is blocked with a clear "Tank is full" message instead of silently failing.

**Multiplayer**
- [ ] Test with 2+ clients (Studio's built-in multi-client test). Confirm each player gets their own tank plot with their own name displayed, and plots don't visually overlap.
- [ ] Have one player catch an Epic/Legendary-tier fish (may need many attempts given low weights — temporarily raise `baseWeight` for Epic/Legendary in `RarityConfig.lua` locally to test faster, then revert). Confirm the other player sees the rare-catch banner.

**Reconnection / persistence**
- [ ] Catch several fish, leave the game (leave Play mode or disconnect), rejoin. Confirm Coins, levels, and fish are all restored.
- [ ] After rejoining, confirm fish that had partial growth show more growth than before (offline growth applied) — you may need to manually shorten `Constants.GROWTH_TIME_SECONDS` and `OFFLINE_GROWTH_CAP_SECONDS` temporarily to observe this quickly rather than waiting 20 minutes/8 hours.
- [ ] Force a server shutdown (stop Play mode) immediately after a purchase/sale and rejoin; confirm the change persisted (validates `BindToClose`/autosave).

**Exploit-style manual probing** (Studio's client console, or a local script temporarily added to a test place — remove before publishing)
- [ ] Fire `CastRequest` in a tight loop from a LocalScript; confirm the server output shows no more than one accepted cast per ~1.5s and no errors/warnings suggesting a crash or duplication.
- [ ] Fire `ReelAttempt` with no preceding `CastRequest`; confirm nothing happens (no fish awarded).
- [ ] Fire `BuyUpgradeRequest` with a fabricated `{track="Rod", cost=0}` payload (note: `cost` is not even read); confirm the real server-computed cost is still charged.
- [ ] Fire `SellFishRequest{all=true}` twice back-to-back; confirm Coins only increase once.

**UI / device**
- [ ] Test in Studio's mobile emulation (phone and tablet aspect ratios) — confirm no UI element is cut off, overlapping, or unreadable, and TextScaled labels remain legible.
- [ ] Test at an unusual desktop aspect ratio (ultra-wide or a small window) — confirm the Shop/Tank panels stay centered and usable.
- [ ] Confirm the reel-bar tap target is large enough to hit reliably on a touch screen.

**Monetization** (only after the user has created real Game Passes/Developer Products and filled in the IDs — see `09_LAUNCH_CHECKLIST.md`)
- [ ] Purchase each Game Pass with a test account; confirm the effect (auto-fishing, 2x Coins, extra tank slots, wider reel window) actually applies without needing to rejoin.
- [ ] Purchase each Developer Product; confirm Coins/growth/bait-boost apply immediately.
- [ ] Rejoin after a purchase; confirm the owned Game Pass effects persist (re-verified via `UserOwnsGamePassAsync` on join).

## Known bugs / open items at handoff

None yet confirmed against a live server — the checklist above has not been run (no Studio access in this session). Treat every box above as "unverified" until the user runs them. Log anything that fails here and in `PROJECT_STATE.md`.

## Design-level risk to watch (not a bug, a balance question)

The reel-timing window (1.2s total, "perfect" centered at 0.6s) and the growth time (20 minutes to full maturity) are first-guess numbers, not playtested ones. After the manual checklist above passes functionally, the very next thing to evaluate is *pacing* — does the first 5 minutes feel too slow (not enough fish) or too easy (every cast is a catch, no skill expression)? Expect to tune `Constants.lua` values after the first real playtest rather than treating the current numbers as final.
