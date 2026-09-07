# Phase 11 — Launch Checklist

This is the list of things that genuinely require you personally (Roblox Studio, your Roblox account, spending/creating real products). Follow it in order. Steps that are exact commands are marked as such; steps that are judgment calls are marked as such too.

## 1. One-time setup: get the code into Roblox Studio

The whole game lives as text files in this repo, synced into Studio via **Rojo** (a free, standard, widely-used Roblox tool — not a paid service, no recurring cost).

1. Install Roblox Studio if you don't have it: https://create.roblox.com/
2. Install the Rojo Studio plugin: in Studio, go to the Toolbox/Plugins, search "Rojo", install the official plugin by the Rojo team. (Alternatively, install the `rojo` CLI on your machine — either path works; the plugin is simpler if you're not comfortable with a terminal.)
3. Create a new, blank Roblox place in Studio and save it (File → Save As) somewhere on your computer — this will be the file Rojo syncs into.
4. In this repo's root folder, there is a `default.project.json` file already set up. If you're using the Rojo CLI: run `rojo serve` from this folder in a terminal. If you're using only the Studio plugin: open the Rojo plugin panel in Studio, click "Connect," and point it at this project folder.
5. In Studio, with the Rojo plugin connected, click **Sync In** (or it may auto-sync). You should see `ReplicatedStorage > Shared`, `ServerScriptService` (with `Server.server.lua` and a `Services` folder), and `StarterPlayer > StarterPlayerScripts` populate with the project's scripts.
6. Press **Play** in Studio. You should see a dock, water, and a grid of tank plots appear automatically (built by `MapBuilderService` at server start — nothing to build by hand). Walk to the glowing cast spot and try casting.

If anything errors on Play, check the Output window in Studio — copy the exact error text; that's the fastest way to diagnose a sync or script issue.

## 2. Manual playtesting

Work through the entire checklist in `docs/07_TESTING.md` — every box there needs a human in Studio, since this development session had no Studio access. Fix anything that breaks before moving further down this checklist.

## 3. Create the real Game Passes and Developer Products

The code ships with **placeholder IDs set to 0** in `src/ReplicatedStorage/Shared/MonetizationIds.lua` — nothing will actually grant anything until you replace them with real IDs. To create them:

1. Publish the place at least once (File → Publish to Roblox — you can unpublish/re-publish later, this just gets it an experience ID). Choose "Private" visibility for now if you don't want the public to find it yet — Game Passes/Developer Products can be created against a place regardless of its visibility setting.
2. In the Creator Hub (https://create.roblox.com/) → your experience → **Monetization**:
   - Create 4 **Game Passes**: "Auto-Fisher" (199 Robux), "2x Coins" (149 Robux), "Extra Tank Room" (249 Robux), "VIP Rod" (179 Robux). Use the descriptions from `docs/08_PRESENTATION.md`.
   - Create 5 **Developer Products**: "500 Coins" (99 Robux), "1,500 Coins" (249 Robux), "4,000 Coins" (599 Robux), "Instant Growth Potion" (79 Robux), "Rare Bait (30 min)" (129 Robux).
   - For each icon, you can use a simple recolored screenshot of the relevant in-game effect, or a plain icon — Roblox requires an icon upload for each; this doesn't need custom art, a clean simple image is enough at launch.
3. Copy each item's numeric ID (shown in the Creator Hub after creation, and in the URL when you view the item).
4. Edit `src/ReplicatedStorage/Shared/MonetizationIds.lua` in this repo, replacing each `0` with the real ID (e.g. `AutoFisher = 4029384756`).
5. Re-sync via Rojo and test each purchase per the "Monetization" section of `docs/07_TESTING.md` using a real (or alt) account — Studio's "Test with a friend"/local server won't process real Robux transactions; you need to actually be in a live published server to test real purchases (Studio does support simulated/free test purchases for your own account on published places — check the current Studio purchase-testing flow in Roblox's docs, since this occasionally changes).

## 4. Experience settings review

In the Creator Hub, under your experience's settings:
- [ ] **Name & description:** use the copy from `docs/08_PRESENTATION.md`.
- [ ] **Icon & thumbnails:** upload per the concepts in `docs/08_PRESENTATION.md`. Minimum 3 thumbnails/screenshots recommended.
- [ ] **Genre:** Simulation (or the closest current Roblox category).
- [ ] **Age rating / content maturity:** answer Roblox's content maturity questionnaire honestly — this game has no violence, no user-generated text chat beyond Roblox's own filtered chat system, no gambling-style loot boxes (Rare Bait is a flat-odds boost, not a purchased randomized reward crate) — should qualify for the standard "All Ages" (9+) rating band, but confirm against Roblox's current questionnaire since categories are periodically updated.
- [ ] **Device compatibility:** enable Mobile, Tablet, Desktop, and Console if available — the UI was built mobile-first (Scale-based sizing) specifically so this isn't a blocker, but verify visually per the device-testing checklist in `07_TESTING.md`.
- [ ] **Voice/Text chat settings:** leave Roblox's default filtered chat; no custom chat system was built (out of scope, avoids a whole moderation surface).
- [ ] **DataStore:** no special configuration needed — `DataStoreService:GetDataStore("PlayerData_v1")` works automatically once the experience is published; just confirm "Enable Studio Access to API Services" is checked in Studio's Game Settings if you want to test DataStore saving *while in Studio* (published live servers always have this enabled).

## 5. Security review before going public

- [ ] Re-read `docs/07_TESTING.md`'s adversarial review section — confirm you understand why each mitigation exists, in case you extend any of this code later (a new remote handler needs the same "never trust the client" discipline).
- [ ] Confirm `MonetizationIds.lua` has real, correct IDs (a wrong ID silently grants nothing — always test every product for real after filling in IDs).
- [ ] Confirm you did NOT leave any test/debug scripts (e.g., a LocalScript that spam-fires remotes for exploit testing) inside the actual place before publishing publicly.

## 6. Multiplayer & mobile testing (final pass)

- [ ] Test with at least 2 real devices or Studio's multi-client test one more time on the fully configured (real product IDs, real settings) place.
- [ ] Test on an actual phone if possible (Roblox mobile app, join your own experience) — Studio's mobile emulation is a good proxy but not a substitute for a real device pass before calling it launched.

## 7. Final economy review

- [ ] Sanity check `UpgradeConfig.lua` and `Constants.lua` numbers one more time after real playtesting — are early upgrades cheap enough to feel frequent? Is Legendary rare enough to feel special but not so rare it never happens?
- [ ] Confirm Game Pass/Developer Product prices feel fair relative to what they give — compare against the revenue model in `docs/05_MONETIZATION.md` and adjust if conversion is very low (price may be too high) or margins feel thin (price may be too low relative to value given).

## 8. Publish for real

- [ ] Set visibility to **Public** in the Creator Hub once everything above is checked off.
- [ ] Announce it (your own social channels, relevant Roblox community spaces if appropriate) — a brand new experience gets very little organic discovery in its first days; some initial push from you is expected and normal.

## Remember

Per the brief: **launch is the beginning of validation, not the finish line.** Move immediately into `docs/10_POST_LAUNCH_ITERATION.md` once real players are in the game — it has the funnel-diagnosis framework to use once you have real impressions/joins/retention data from the Creator Hub Analytics tab.
