# Phase 10 — Presentation

## Name

**Working title: "Fish Tank Simulator"**

Rationale: Roblox discovery is still heavily keyword/search-driven for a new experience with no existing audience. "Simulator" and "Tank" are both established, high-volume search terms players already use when they know what mood they're in ("I want to play a simulator"). A literal, descriptive name also means the thumbnail and title agree with each other instantly — no guessing required from a cold impression.

Alternatives considered and set aside for later A/B testing once the game has impressions to test against:
- *"Aqua Tycoon"* — leans on "Tycoon" search volume instead, but undersells the collection/pet-like attachment to individual fish, which is the actual retention hook.
- *"Tidal Collector"* — more evocative, less discoverable; a player has to already know the game to search this term.
- *"Fish Tank Simulator: Catch, Grow & Trade"* — same core name with a subtitle spelling out the loop; worth testing as a thumbnail/description variant rather than the title itself (title length is constrained and front-loaded keywords matter most).

## Icon concept

A single large, bright fish (Legendary-tier coloring — gold/orange with a particle sparkle) inside a simple rounded fish-tank silhouette, on a high-contrast blue-to-white gradient background. No text in the icon (icons render small; text is illegible at icon size and Roblox's own title text already carries the name). Roblox icons are a 512x512 upload — this can be built in Roblox Studio's built-in tools or a free image editor from a screenshot of the actual procedural Legendary fish model rendered large, rather than commissioning custom art.

## Thumbnail concepts (3–5 images required at launch)

1. A wide shot of a player's tank room showing several colorful fish of different rarities swimming, with the rarest one glowing/sparkling in the foreground — communicates "collect fish" instantly.
2. A close-up action shot of the cast/reel minigame UI mid-catch, with a "Legendary Catch!" style banner visible — communicates the active gameplay moment, not just the idle layer.
3. A comparison shot: a small starter tank next to a large, upgraded multi-room tank full of fish — communicates progression at a glance.
4. (Optional, once real players exist) A shot with two visible player avatars near each other's tanks — communicates the social/multiplayer angle.

All thumbnails must be actual in-game screenshots/renders of real gameplay — never a mockup that shows something the game doesn't actually do (the brief's own "no misleading thumbnails" rule, and Roblox policy).

## Game description (long form, for the experience page)

> Cast a line, catch colorful fish, and watch them grow in your very own tank! Every fish you catch is unique — from common Minnows to shimmering Legendary Koi. Sell fish to upgrade your rod and tank, show off your rarest catches to other players, and come back tomorrow to see how much your tank has grown while you were away. No pay-to-win — just cast, collect, and grow.
>
> • Quick, satisfying cast-and-catch gameplay
> • Fish grow over time, even while you're offline
> • Six species and five rarity tiers to collect (more added regularly!)
> • Show off your tank to other players
> • Upgrade your rod, tank, and bait to catch bigger and rarer fish
> • Daily rewards for returning players

## Short description (search-result blurb, ~150 chars)

> Cast, catch, and grow your own fish tank! Collect rare fish, upgrade your gear, and show off your collection. New species added regularly.

## Onboarding text (in-experience, first session)

- On spawn: a glowing prompt at the cast spot — no text popup needed, the glow + "Cast Line" ProximityPrompt label does the job.
- After first catch: a one-line tooltip — "Nice catch! Open your Tank to see it, or keep fishing."
- After 3rd catch or tank at 50% capacity: "Tank filling up? Sell fish for Coins in the Tank menu, or upgrade your tank in the Shop."
- First time opening Shop: a one-line tooltip explaining rarity tiers exist and better rods catch rarer fish (paired with the visual rarity-color chart already implicit in the Shop's fish-adjacent UI).

## Update log format

Keep it short and player-facing, posted in the experience's update notes / a pinned social channel if one exists:

```
[Month Day] — v0.x
+ New: [species/biome/feature name] — [one line on what it does]
+ Balance: [what changed and why, briefly]
+ Fix: [bug fixed, only if player-visible]
```

Consistency matters more than length — a short, predictable weekly/biweekly note signals an actively maintained game, which itself helps retention and discovery.

## Monetization descriptions (for the Shop UI and Game Pass/Product store pages)

Keep every description honest about exactly what it does — no vague "get an advantage!" language:
- **Auto-Fisher:** "Automatically casts and reels for you, even while you're doing other things in-game."
- **2x Coins:** "Doubles the Coins you earn from selling fish."
- **Extra Tank Room:** "Adds 6 extra tank slots on top of what you can unlock for free."
- **VIP Rod:** "A wider reel timing window makes it easier to land a great catch, plus an exclusive rod skin."
- **Coin Packs:** "Instantly get Coins to spend in the Shop."
- **Instant Growth Potion:** "Instantly matures one of your fish to full size."
- **Rare Bait (30 min):** "Increases your odds of catching a rare fish for the next 30 minutes."

## Screenshots needed (for the store page, beyond thumbnails)

- Tank room, full and decorated with several fish.
- Shop UI open, showing upgrade options.
- The cast/reel minigame mid-action.
- A rare-catch server announcement banner.
- (Post-launch) A multiplayer shot with two players' tanks visible.

## Trailer concept (optional, only worth doing once organic traction exists)

15–20 seconds: cast → catch (with a satisfying sound/visual sting) → quick cut to tank filling with fish → quick cut to a Legendary catch + server announcement → end card with the name and "Play Now." Roblox trailers perform best short and gameplay-only — no narration needed, and a solo dev shouldn't spend more than an afternoon on this.

## Discovery keywords (for the experience's genre/tag settings and description)

fish, fishing, simulator, tank, aquarium, collect, pets, tycoon, idle, casual, relaxing — chosen to overlap with both the "simulator" search audience and the (smaller, but relevant) "fishing"/"aquarium" search audience, without directly competing on the single word "fishing" that *Fisch* already dominates.
