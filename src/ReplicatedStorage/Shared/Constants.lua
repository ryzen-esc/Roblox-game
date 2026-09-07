--- Tunable numbers for the whole game. Change balance here, not scattered through services.
local Constants = {}

-- Fishing
Constants.CAST_COOLDOWN_SECONDS = 1.5 -- minimum time between CastRequest calls, server-enforced
Constants.REEL_WINDOW_SECONDS = 1.2 -- how long the reel target window stays open (visual + scoring)
Constants.REEL_TIMEOUT_SECONDS = 4 -- server auto-resolves (as a miss) if no ReelAttempt arrives in time
Constants.PERFECT_REEL_SECONDS = 0.6 -- server-measured reaction time that counts as a "perfect" catch

-- Growth / tank
Constants.GROWTH_TIME_SECONDS = 20 * 60 -- time for a fish to go from growth 0 to 1 while online
Constants.OFFLINE_GROWTH_CAP_SECONDS = 8 * 60 * 60 -- max credited offline growth time (8 hours)
Constants.BASE_TANK_CAPACITY = 6 -- starter tank slots before any upgrade

-- Progression caps (MVP)
Constants.MAX_ROD_LEVEL = 10
Constants.MAX_TANK_LEVEL = 10
Constants.MAX_BAIT_LEVEL = 5

-- Data / saving
Constants.AUTOSAVE_INTERVAL_SECONDS = 120
Constants.DATASTORE_MAX_RETRIES = 5
Constants.DATASTORE_RETRY_BASE_SECONDS = 2

-- Rate limiting backstop (independent of game-logic cooldowns above)
Constants.REMOTE_MIN_INTERVAL_SECONDS = 0.25

-- Daily reward
Constants.DAILY_RESET_HOURS = 24
Constants.DAILY_STREAK_MAX_DAYS = 7

-- Rare-catch announcement threshold (rarity ids at/above this index in RarityConfig trigger a broadcast)
Constants.ANNOUNCE_MIN_RARITY_INDEX = 4 -- Epic and Legendary (see RarityConfig order)

return Constants
