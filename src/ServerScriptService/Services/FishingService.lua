local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Shared.RarityConfig)
local FishData = require(ReplicatedStorage.Shared.FishData)
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)

--- Server-authoritative cast/reel state machine. The client only ever sends "I want to
-- cast" and "I tapped now" -- every outcome (timing, rarity, species, size) is decided
-- here using the server's own clock and RNG, never anything the client claims.
local FishingService = {}

local AUTO_FISHER_INTERVAL_SECONDS = 8
local AUTO_FISHER_QUALITY = 0.6 -- fixed, average quality: a convenience, not a skill shortcut

local pendingAttempts = {} -- [userId] = { token = number, startClock = number }
local nextToken = {} -- [userId] = number

local remotes = nil
local rateLimiter = nil
local announcementService = nil
local monetizationService = nil
local achievementService = nil
local analyticsService = nil

local function fishCount(data): number
	local count = 0
	for _ in data.fish do
		count += 1
	end
	return count
end

local function effectiveCapacity(player: Player, data): number
	local bonus = monetizationService and monetizationService.getExtraTankCapacity(player) or 0
	return UpgradeConfig.getTankCapacity(data.tankLevel) + bonus
end

local function effectiveRareBias(player: Player, data): number
	local bias = UpgradeConfig.getBaitRareBias(data.baitLevel)
	if data.rareBaitBoostExpiresUnix and data.rareBaitBoostExpiresUnix > os.time() then
		bias *= 1.5
	end
	return bias
end

--- Rolls and awards a fish for the given quality (0..1), pushes state + result to the
-- client, and fires a server-wide announcement for rare catches. Shared by manual reels
-- and the Auto-Fisher convenience loop so both paths use identical, server-only RNG.
local function rollAndAwardFish(player: Player, data, quality: number)
	local rareBias = effectiveRareBias(player, data)
	local rarityId = RarityConfig.rollRarity(data.rodLevel, rareBias)
	local speciesId = FishData.rollSpecies(data.rodLevel, FishData.getFeaturedSpeciesId())
	local sizeRoll = math.clamp(quality * (0.7 + math.random() * 0.3), 0, 1)

	local uid = tostring(data.nextFishUid)
	data.nextFishUid += 1
	data.fish[uid] = {
		speciesId = speciesId,
		rarityId = rarityId,
		sizeRoll = sizeRoll,
		growth = 0,
		caughtAt = os.time(),
	}

	data.totalFishCaught = (data.totalFishCaught or 0) + 1
	data.rarityCatchCounts[rarityId] = (data.rarityCatchCounts[rarityId] or 0) + 1

	if analyticsService then
		analyticsService.logFunnelStepOnce(player, data, "FirstCatch")
	end
	if achievementService then
		achievementService.checkAll(player, data)
	end

	PlayerDataService.sync(player)
	remotes[RemoteNames.CATCH_RESULT]:FireClient(player, {
		success = true,
		fish = { uid = uid, speciesId = speciesId, rarityId = rarityId, sizeRoll = sizeRoll },
	})

	if announcementService and RarityConfig.getIndex(rarityId) >= Constants.ANNOUNCE_MIN_RARITY_INDEX then
		announcementService.announceRareCatch(player, speciesId, rarityId)
	end
end

local function resolveAttempt(player: Player, token: number, playerTapped: boolean)
	local pending = pendingAttempts[player.UserId]
	if not pending or pending.token ~= token then
		return -- already resolved (timeout beat the tap, or vice versa)
	end
	pendingAttempts[player.UserId] = nil

	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local elapsed = os.clock() - pending.startClock
	local reelWindow = Constants.REEL_WINDOW_SECONDS + (monetizationService and monetizationService.getReelWindowBonus(player) or 0)

	if not playerTapped or elapsed > reelWindow then
		remotes[RemoteNames.CATCH_RESULT]:FireClient(player, { success = false, reason = "missed" })
		return
	end

	local quality = math.clamp(1 - math.abs(elapsed - Constants.PERFECT_REEL_SECONDS) / Constants.PERFECT_REEL_SECONDS, 0, 1)
	rollAndAwardFish(player, data, quality)
end

local function onCastRequest(player: Player)
	if not rateLimiter:allow(player, "cast", Constants.CAST_COOLDOWN_SECONDS) then
		return
	end
	if not PlayerDataService.isLoaded(player) then
		return
	end
	if pendingAttempts[player.UserId] then
		return -- already mid-cast, ignore duplicate requests
	end

	local data = PlayerDataService.get(player)
	if fishCount(data) >= effectiveCapacity(player, data) then
		remotes[RemoteNames.CATCH_RESULT]:FireClient(player, { success = false, reason = "tank_full" })
		return
	end

	if analyticsService then
		analyticsService.logFunnelStepOnce(player, data, "FirstCast")
	end

	nextToken[player.UserId] = (nextToken[player.UserId] or 0) + 1
	local token = nextToken[player.UserId]
	pendingAttempts[player.UserId] = { token = token, startClock = os.clock() }

	remotes[RemoteNames.CAST_STARTED]:FireClient(player, { reelWindowSeconds = Constants.REEL_WINDOW_SECONDS })

	task.delay(Constants.REEL_TIMEOUT_SECONDS, function()
		resolveAttempt(player, token, false)
	end)
end

local function onReelAttempt(player: Player)
	if not rateLimiter:allow(player, "reel", 0.1) then
		return
	end

	local pending = pendingAttempts[player.UserId]
	if not pending then
		return
	end

	resolveAttempt(player, pending.token, true)
end

--- Auto-Fisher game pass: runs entirely server-side on a fixed interval so a modified
-- client cannot fake or accelerate it. Only acts on players confirmed (server-side) to
-- own the pass, who are not already mid-cast and have tank space.
local function autoFisherLoop()
	while true do
		task.wait(AUTO_FISHER_INTERVAL_SECONDS)
		if not monetizationService then
			continue
		end

		for _, player in Players:GetPlayers() do
			if
				PlayerDataService.isLoaded(player)
				and monetizationService.ownsPass(player, "AutoFisher")
				and not pendingAttempts[player.UserId]
			then
				local data = PlayerDataService.get(player)
				if fishCount(data) < effectiveCapacity(player, data) then
					rollAndAwardFish(player, data, AUTO_FISHER_QUALITY)
				end
			end
		end
	end
end

function FishingService.init(
	remotesTable,
	rateLimiterInstance,
	announcementServiceModule,
	monetizationServiceModule,
	achievementServiceModule,
	analyticsServiceModule
)
	remotes = remotesTable
	rateLimiter = rateLimiterInstance
	announcementService = announcementServiceModule
	monetizationService = monetizationServiceModule
	achievementService = achievementServiceModule
	analyticsService = analyticsServiceModule

	remotes[RemoteNames.CAST_REQUEST].OnServerEvent:Connect(onCastRequest)
	remotes[RemoteNames.REEL_ATTEMPT].OnServerEvent:Connect(onReelAttempt)

	Players.PlayerRemoving:Connect(function(player)
		pendingAttempts[player.UserId] = nil
		nextToken[player.UserId] = nil
	end)

	task.spawn(autoFisherLoop)
end

return FishingService
