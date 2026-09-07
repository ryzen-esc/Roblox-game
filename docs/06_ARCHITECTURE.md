# Phase 6 — Technical Architecture

## Toolchain decision: Rojo

The project is built as a **Rojo** project — Luau source lives as plain text files in this git repo, and `default.project.json` maps them onto the Roblox DataModel. This lets the entire game be written, reviewed, and version-controlled here, with the user only needing Roblox Studio + the free Rojo plugin to sync and press Play. This is the standard solo-developer workflow and is what makes it possible to build this game in a text-only environment. Exact sync steps are in `09_LAUNCH_CHECKLIST.md`.

## Why the whole map is generated in code

Rather than requiring the user to hand-place a dock, water, and per-player tank plots in Studio, `MapBuilderService` procedurally constructs the entire minimal environment (baseplate, water, dock, spawn point, and a grid of tank-room plots) from parts at server start. Combined with procedurally generated fish (`FishModelFactory`), this means **zero manual building and zero asset uploads are required to get the MVP running** — sync with Rojo and press Play. Real hand-built environment art and imported fish meshes are a legitimate future upgrade once the loop is validated, not a blocker now.

## Folder structure

```
default.project.json
src/
  ReplicatedStorage/
    Shared/
      Constants.lua          -- tunable numbers (cooldowns, growth time, offline cap, etc.)
      RemoteNames.lua         -- canonical list of remote names, shared by client & server
      RarityConfig.lua        -- rarity tiers: id, name, color, multiplier, weight, minRodLevel
      FishData.lua            -- species table: id, name, baseValue, bodyColor
      UpgradeConfig.lua       -- rod/tank/bait level costs & effects
      FishModelFactory.lua    -- builds a procedural fish Model from species+rarity+size
  ServerScriptService/
    Server.server.lua         -- bootstrap: requires services in dependency order
    Services/
      RemoteSetup.lua         -- creates the Remotes folder + RemoteEvents in ReplicatedStorage
      RateLimiter.lua         -- generic per-player-per-key cooldown/token utility
      MapBuilderService.lua   -- procedurally builds dock, water, spawn, tank plots
      PlayerDataService.lua   -- DataStore load/save, session cache, offline growth, plot assignment
      FishingService.lua      -- cast/reel state machine, server-authoritative RNG
      TankService.lua         -- fish growth ticking, selling, tank capacity
      ShopService.lua         -- rod/tank/bait upgrade purchases (Coins)
      MonetizationService.lua -- Game Pass checks + Developer Product ProcessReceipt
      AnnouncementService.lua -- server-wide rare-catch broadcast
      DailyRewardService.lua  -- login streak tracking & claim
  StarterPlayer/
    StarterPlayerScripts/
      Client.client.lua               -- bootstrap: builds UI, wires controllers
      Controllers/
        ClientState.lua               -- client-side mirror of the server's PlayerDataSync payload
        FishingController.lua         -- cast prompt, reel minigame rendering, remote calls
        UIController.lua              -- builds all ScreenGui via code (HUD, Shop, Tank view)
        TankRenderController.lua      -- renders the local player's fish as models in their plot
        ShopController.lua            -- Coin upgrade rows + Game Pass / Developer Product buttons
        InventoryController.lua       -- Coins label, sell list, daily reward popup
```

Also `ReplicatedStorage/Shared/MonetizationIds.lua` holds the Game Pass / Developer Product ID table, shared by `MonetizationService` (server, grants) and `ShopController` (client, prompts purchase) so there is one source of truth for IDs.

No `StarterGui` instances are hand-built — all UI is constructed by `UIController.lua` at runtime so it is fully text/version-controlled and needs no Studio UI editing to change.

## Data model

Single DataStore (`PlayerData_v1`), one key per `UserId`:

```lua
{
  coins = number,
  rodLevel = number,
  tankLevel = number,
  baitLevel = number,
  rebirths = number,
  fish = {
    [fishUid] = { speciesId, rarityId, sizeRoll, growth, caughtAt }
  },
  dailyStreak = { lastClaimUnix, streakCount },
  achievements = { [achievementId] = true },
  lastSaveUnix = number,
}
```

- **Growth** is 0→1; sell value = `baseValue[species] * rarityMultiplier * (0.5 + 0.5*growth)`. A fish is always sellable, but waiting for full growth roughly doubles its value — a soft incentive, never a hard gate.
- **Offline growth** is computed once on load: `elapsed = min(now - lastSaveUnix, OFFLINE_CAP_SECONDS)` (cap = 8 hours) applied to every fish's growth. This rewards returning without making multi-day AFK idling dominant.
- Rarity and species are decoupled (a rarity is a modifier applied on top of any species — recolor, particle, value multiplier), so N species × M rarities gives N×M meaningful variety from only N+M authored data rows. This is the "cheap content" lever for future updates.

## Remote protocol (all under `ReplicatedStorage.Remotes`)

| Remote | Direction | Purpose |
|---|---|---|
| `CastRequest` | C→S | Player wants to start a cast. |
| `CastStarted` | S→C | Server confirms and tells the client the reel-window timing to *render* (visual only). |
| `ReelAttempt` | C→S | Client signals "I tapped now." Server measures elapsed time **itself** from when it sent `CastStarted` — the client's own claimed timestamp is never trusted. |
| `CatchResult` | S→C | Server tells the client what was caught (species, rarity, size, fish list) after resolving everything server-side. |
| `SellFishRequest` | C→S | Sell one fish (by id) or all. Server re-validates the fish exists in the authoritative session table before crediting Coins. |
| `BuyUpgradeRequest` | C→S | Buy next rod/tank/bait level. Server recomputes the cost from `UpgradeConfig` and the player's *current authoritative* level — the client never sends a price. |
| `ClaimDailyRewardRequest` | C→S | Claim today's login reward if eligible (server checks the timestamp). |
| `PlayerDataSync` | S→C | Full/partial state push after load and after every mutating action, so the client UI is always a mirror of server truth, never a source of it. |
| `RareCatchAnnouncement` | S→C (broadcast) | Server-wide message when any player catches Epic/Legendary rarity. |

Game Pass and Developer Product purchases use Roblox's own client APIs (`MarketplaceService:PromptGamePassPurchase`, `PromptProductPurchase`) directly from the Shop UI — no custom remote is needed to *start* a purchase. The server is the sole authority for *granting* anything, via `MarketplaceService.PromptGamePassPurchaseFinished` (re-verified with `UserOwnsGamePassAsync`) and the mandatory `ProcessReceipt` callback for Developer Products.

## Server-authoritative security design

Assume every client is hostile and can fire any remote with any payload at any time.

1. **State machine per player, not per request.** A player must be `Idle` to send `CastRequest` (server flips them to `Waiting`); `ReelAttempt` is only accepted while `Waiting`, and the server auto-resolves (as a miss) any attempt left open past a timeout (4s) so a client can't hold a "free" pending catch open indefinitely.
2. **Server measures time, not the client.** Reaction-time scoring for catch *size* is computed from the server's own clock between sending `CastStarted` and receiving `ReelAttempt`. A modified client can claim anything it wants in the payload; the payload's timing fields are ignored.
3. **Rarity/species RNG is rolled entirely server-side**, weighted by the player's *authoritative* rod level pulled from the session cache — never from anything the client sends.
4. **Currency and levels are never accepted from the client.** `BuyUpgradeRequest` carries only *which* upgrade track to level up; the server looks up the player's current level and the next cost itself. `SellFishRequest` carries only a fish id; the server looks up that fish's real data before paying out and only pays out once (removed from the table immediately, before yielding on anything).
5. **Per-player action lock** for anything that touches Coins (buy/sell) — a simple boolean flag serializes these against rapid double-fires of the same remote from a modified client, preventing double-spend races.
6. **Rate limiting** (`RateLimiter.lua`) wraps every remote handler with a minimum interval per player per remote, independent of the game-logic cooldowns above — a generic backstop against spam/DoS-style abuse from a single client.
7. **DataStore safety:** `UpdateAsync` (never blind `SetAsync`) so a save merges against the latest stored value; `pcall`-wrapped with retry + exponential backoff (up to 5 attempts); autosave on an interval, on `PlayerRemoving`, and inside `game:BindToClose()` with a time budget so the server doesn't get killed mid-save.
8. **Developer Product idempotency:** `ProcessReceipt` must be safe to call twice for the same receipt (Roblox retries undelivered receipts) — grant is checked against a "already processed" set in the player's saved data before granting again, and the callback returns `PurchaseGranted` only after the grant is durably applied.

## What is intentionally NOT built (and why)

- **No external backend/API.** Everything above runs entirely on Roblox's own servers using `DataStoreService`, `MarketplaceService`, and `AnalyticsService` — all free, first-party, and don't depend on the developer's own machine or any paid infrastructure.
- **No RemoteFunctions.** All client↔server communication uses `RemoteEvent`s in a fire-and-confirm pattern (`PlayerDataSync` as the source of truth) rather than `RemoteFunction:InvokeServer`, avoiding the yield/timeout and exploit-surface issues RemoteFunctions are known for.
- **No custom UI built in Studio.** All UI is Luau code (`UIController.lua`), which keeps the entire game reviewable and diffable as text in this repo without needing Studio access to iterate on layout.
